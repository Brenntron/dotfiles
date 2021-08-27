class AdminTask
  def self.available_tasks
    self.instance_methods - Object.instance_methods
  end

  def self.execute_task(name, args)
    admin_task = AdminTask.new
    morsel = Morsel.create({:output => " "})
    admin_task.send(name.to_sym, morsel.id, **args)

    morsel
  end

  ######NOTES#######
  #LIKE A RAKE TASK, EACH TASK SHOULD FIT INTO **ONE** INSTANCE METHOD
  #AND IT **MUST** BE AN INSTANCE METHOD TO BE INCLUDED AS AN ELIGIBLE
  #TASK TO RUN
  #def task_name(morsel_id, args)    <--- args will be a hash converted from json
  #end
  #handle_asynchronously :task_name    <--- include this on the line below your task method so that delayed job picks it up


  #Use this test method as a template
  def test_task(morsel_id, args)
    morsel = Morsel.find(morsel_id)
    morsel.output += "\n##################################\n"
    morsel.output += "this is a test, this is only a test:\n"
    morsel.output += "args provided are as follows:\n"
    morsel.output += "#{args.inspect}\n"
    morsel.output += "####################################\n"
    morsel.save
  end
  handle_asynchronously :test_task
  #end of template

  #### REAL TASKS BELOW #######

  def remove_screenshot_jobs(morsel_id, args)
    morsel = Morsel.find(morsel_id)
    low_priority_jobs = DelayedJob.where(:queue => "screen_grab")
    morsel.output += "############################################\n"
    morsel.output += "starting removal of old screenshot jobs now.\n"
    morsel.output += "total entries found: #{low_priority_jobs.size.to_s}\n"
    morsel.output += "running.....\n"
    morsel.save
    low_priority_jobs.destroy_all
    morsel.output += "completed.\n"
    morsel.output += "############################################\n"
    morsel.save

  end

  def sync_disputes_with_ti(morsel_id, is_current: true)

    rep_disputes = is_current ? Dispute.where.not(status: ::Dispute::RESOLVED) : Dispute.all

    rep_disputes.where(ticket_source: 'talos-intelligence').in_batches(of: 500) do |disputes|
      disputes.each do |dispute|
        message = Bridge::DisputeEntryUpdateStatusEvent.new
        message.post_entries(dispute.dispute_entries)
      end
    end

    morsel = Morsel.find(morsel_id)
    morsel.output += "#{rep_disputes.count} disputes are queued for updating."
    morsel.save
    # no need to handle asynchronously since the bridge jobs already do this
  end

  def sync_complaints_with_ti(morsel_id, is_current: true)

    comps = is_current ? Complaint.where.not(status: ::Complaint::COMPLETED) : Complaint.all

    comps.where(ticket_source: 'talos-intelligence').in_batches(of: 500) do |complaints|
      complaints.each do |complaint|
        message = Bridge::ComplaintUpdateStatusEvent.new
        message.post_complaint(complaint)
      end
    end

    morsel = Morsel.find(morsel_id)
    morsel.output += "#{comps.count} complaints are queued for updating."
    morsel.save
    # no need to handle asynchronously since the bridge jobs already do this
  end

  def sync_file_rep_disp_with_ti(morsel_id, is_current: true)

    file_rep_disps = is_current ? FileReputationDispute.where.not(status: ::FileReputationDispute::STATUS_RESOLVED) : FileReputationDispute.all

    file_rep_disps.where(sandbox_key: ::FileReputationDispute::SANDBOX_KEY_TI_FORM).in_batches(of: 500) do |disputes|
      disputes.each do |dispute|
        conn = ::Bridge::FileRepUpdateStatusEvent.new(addressee: "talos-intelligence")
        conn.post(dispute, source_authority: "talos-intelligence", source_key: dispute.ticket_source_key)
      end
    end

    morsel = Morsel.find(morsel_id)
    morsel.output += "#{file_rep_disps.count} file reputation disputes are queued for updating."
    morsel.save
    # no need to handle asynchronously since the bridge jobs already do this
  end

  def resubmit_category_tickets(morsel_id, args)
    range_from = args[:from]  #must be in format yyyy-mm-dd 2020-12-24
    range_to = args[:to]

    id_range_from = args[:id_from]  #id range  {"id_from":"100000","id_to":"100100"}
    id_range_to = args[:id_to]

    url_range = args[:url]  #{"uri":"www.google.com, www.yahoo.com, www.msn.com"}

    morsel = Morsel.find(morsel_id)
    if range_from.present? && range_to.present?
      complaint_entries = ComplaintEntry.where("updated_at >= '#{range_from}' and updated_at <= '#{range_to}'").where(:status => ['COMPLETED','RESOLVED','CLOSED'])
    end
    if id_range_from.present? && id_range_to.present?
      complaint_entries = ComplaintEntry.where("id >= '#{id_range_from}' and id <= '#{id_range_to}'").where(:status => ['COMPLETED','RESOLVED','CLOSED'])
    end
    if url_range.present?
      url_list = url_range.split(",").map {|url| url.strip}
      complaint_entries = []

      url_list.each do |url|
        entries_found = ComplaintEntry.where(:uri_as_categorized => url).where(:status => ['COMPLETED','RESOLVED','CLOSED']).order("case_resolved_at DESC")
        if entries_found.present?
          complaint_entries << entries_found.first
        end
      end
    end


    morsel.output += "total entries: #{complaint_entries.size} \n\n"
    Thread.new do
      complaint_entries.each do |complaint_entry|
        puts "running complaint entry: #{complaint_entry.id} : #{complaint_entry.hostlookup}\n"
        morsel.output += "running complaint entry: #{complaint_entry.id} : #{complaint_entry.hostlookup}\n"
        morsel.save
        log = complaint_entry.resubmit_to_rule_api
        log.each do |l_entry|
          morsel.output += l_entry + "\n"
        end
        morsel.save
      end
      morsel.output += "\nCompleted task."
      morsel.save
    end

    morsel
  end

  def parse_complaint_entry_uris(morsel_id)
    morsel = Morsel.find(morsel_id)
    entries = ComplaintEntry.where(entry_type: 'URI/DOMAIN').where("domain is null or domain = ''")
    morsel.output += "\n##################################\n"
    morsel.output += "Updated Complaint Entries\n"
    morsel.output += "complaint_entry_id : complaint_id : uri\n"
    entries.each do |entry|
      parsed_uri = Complaint.parse_url(entry.uri)
      entry.domain = parsed_uri[:domain]
      entry.subdomain = parsed_uri[:subdomain] unless entry.subdomain.present?
      entry.path = parsed_uri[:path] unless entry.path.present?
      entry.save
      morsel.output += "#{entry.id} : #{entry.complaint_id} : #{entry.uri}\n"
    end
    morsel.output += "####################################\n"
    morsel.save
  end
  handle_asynchronously :parse_complaint_entry_uris

  def ngfw_clusters_import(morsel_id, args)
    morsel = Morsel.find(morsel_id)
    morsel.output += "############################################\n"
    morsel.output += "starting NGFW clusters import now.\n"
    morsel.output += "running.....\n"
    morsel.save
    Ngfw::Importer.import_without_delay
    morsel.output += "completed.\n"
    morsel.output += "############################################\n"
    morsel.save

  end
end
