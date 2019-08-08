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
end
