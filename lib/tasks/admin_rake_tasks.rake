require 'pry'
require 'rake'

namespace :escalations do

  task :run_wbnp_pull => :environment  do
    Complaint.get_latest_wbnp_complaints(true)
  end

  task :check_file_reputations do
    FileReputationDispute.check_for_rep_updates
  end

  task :check_and_unsubscribe do
    FileReputationDispute.check_and_unsubscribe
  end

  task :populate_complaint_entry_credits => :environment do
    resolutions = ['INVALID', 'FIXED', 'UNCHANGED', 'DUPLICATE']
    resolutions_mapping = {
      'INVALID' => ComplaintEntryCredit::INVALID,
      'FIXED' => ComplaintEntryCredit::FIXED,
      'UNCHANGED' => ComplaintEntryCredit::UNCHANGED,
      'DUPLICATE' => ComplaintEntryCredit::DUPLICATE
    }

    credited_complaint_ids = ComplaintEntryCredit.pluck(:complaint_entry_id).uniq
    total_complaints = ComplaintEntry.where(resolution: resolutions).where.not(id: credited_complaint_ids)
    total_count = total_complaints.count
    processed = 0
    total_complaints.find_each do |entry|
      if entry.case_resolved_at.nil?
        processed += 1
        puts "#{processed} of #{total_count} processed"
        next
      end
      ComplaintEntryCredit.find_or_create_by(
        user_id: entry.user_id,
        complaint_entry_id: entry.id,
        credit: resolutions_mapping[entry.resolution],
        created_at: entry.case_resolved_at)

      processed += 1
      puts "#{processed} of #{total_count} processed"
    end
  end

  task :populate_ngfw_platform => :environment do
    ngfw_platform = Platform.where('LOWER(internal_name) LIKE ?', '%ngfw%').first # there is no ILIKE in mysql...

    ComplaintTag.where('LOWER(name) LIKE ?', '%ngfw%').each do |tag|
      puts tag.name
      tag.complaints.each do |complaint|
        puts "processing #{complaint.complaint_entries.count} entries for complaint id #{complaint.id}"
        complaint.update(platform_id: ngfw_platform.id)
        complaint.complaint_entries.update_all(platform_id: ngfw_platform.id)
      end
    end
  end

  task :run_clusters_import => :environment do
    Clusters::Importer.import_without_delay
  end

  ################AUTO RESOLVE##############################

  task :auto_resolve_tickets => :environment do
    disputes_to_auto_resolve = Dispute.where(:status => Dispute::PROCESSING)

    disputes_to_auto_resolve.each do |new_dispute|

      dispute_packet = JSON.parse(new_dispute.bridge_packet) rescue nil
      if dispute_packet.blank?
        next
      end

      begin
        new_dispute.dispute_entries.each do |dispute_entry|

          if dispute_entry.status != DisputeEntry::PROCESSING
            next
          end

          if dispute_entry.claim.blank?
            dispute_entry.build_claim(dispute_packet)
            dispute_entry.reload
          end
          if dispute_entry.auto_resolve_log.blank?
            initial_log = "--------Starting Data---------<br>"
            initial_log += "suggested disposition: #{dispute_entry.suggested_disposition}<br>"
            initial_log += "effective disposition info: #{dispute_entry.running_verdict.inspect.to_s}<br>"
            initial_log += "-----------------------------<br>"

            dispute_entry.auto_resolve_log += initial_log
            dispute_entry.save!
          end
          dispute_entry.reload
          begin
            auto_resolve_params = {}
            auto_resolve_params[:entry_claim] = dispute_entry.claim
            auto_resolve_params[:dispute_entry] = dispute_entry

            AutoResolve.process_auto_resolution(auto_resolve_params)
          rescue
            dispute_entry.status = DisputeEntry::NEW
            dispute_entry.save
          end


        end

        new_dispute.reload
        new_dispute.auto_check_entries_and_update(Dispute::ALL_AUTO_RESOLVED)


        message = Bridge::DisputeEntryUpdateStatusEvent.new
        message.post_entries(new_dispute.dispute_entries)
      rescue Exception => e
        morsel_output = "AUTO RESOLVE EXCEPTION FOR DISPUTE #{new_dispute.id.to_s}:\n\n"
        morsel_output += e.message + "\n"
        morsel_output += e.backtrace.join("\n")

        morsel = Morsel.create(:output => morsel_output)

        Rails.logger.error morsel_output

        new_dispute.status = Dispute::PROCESSING
        new_dispute.save
      end


    end

  end

  ##########################################################
  task :convert_files_from_bugzilla_to_local => :environment do

    morsel = Morsel.new
    morsel.output = ""
    morsel.output += "Starting migration...\n"
    morsel.output += "Grabbing Bugzilla rest session...\n"
    bugzilla_rest_session = BugzillaRest::Session.default_session

    #HANDLE DISPUTE EMAIL ATTACHMENTS
    morsel.output += "Grabbing all dispute email attachments...\n"
    all_attachments = DisputeEmailAttachment.all

    dispute_ids = all_attachments.map {|att| att.dispute_email.dispute&.id}

    dispute_ids.each do |dispute_id|
      begin
        morsel.output += "Starting Dispute #{dispute_id}...\n"
        bug_proxy = bugzilla_rest_session.build_bug(id: dispute_id)
        bug_attachments = bug_proxy.attachments

        bug_attachments.each do |bug_attachment|
          begin
            full_file_path = DisputeEmailAttachment::FULL_FILE_DIRECTORY_PATH + "#{bug_attachment.id}/#{bug_attachment.file_name}"

            directory_to_create = Pathname(full_file_path)
            directory_to_create.dirname.mkpath

            File.open(full_file_path, 'wb') { |f| f.write bug_attachment.file_contents }
            if open(full_file_path).read != nil
              dispute_email_attachment = all_attachments.find {|attach| attach.id == bug_attachment.id}
              dispute_email_attachment.direct_upload_url = full_file_path
              dispute_email_attachment.save
            else
              morsel.output += "attachment #{bug_attachment.id} was blank, didn't save. investigate \n"
            end
          rescue
            morsel.output += "Failed to migration file with attachment id #{bug_attachment.id}...\n"
            morsel.output += "moving on...\n"
          end

        end
      rescue
        morsel.output += "Failed to successfully build bug with dispute id #{dispute_id}...\n"
        morsel.output += "moving on...\n"
      end

    end
    morsel.save
    #HANDLE SDR ATTACHMENTS
    morsel.output += "Grabbing all sdr attachments...\n"
    all_attachments = SenderDomainReputationDisputeAttachment.all

    dispute_ids = all_attachments.map {|att| att.sender_domain_reputation_dispute&.id}

    dispute_ids.each do |dispute_id|
      begin
        morsel.output += "Starting SDR #{dispute_id}...\n"
        bug_proxy = bugzilla_rest_session.build_bug(id: dispute_id)
        bug_attachments = bug_proxy.attachments

        bug_attachments.each do |bug_attachment|
          begin
            full_file_path = SenderDomainReputationDisputeAttachment::FULL_FILE_DIRECTORY_PATH + "#{bug_attachment.id}/#{bug_attachment.file_name}"

            directory_to_create = Pathname(full_file_path)
            directory_to_create.dirname.mkpath

            File.open(full_file_path, 'wb') { |f| f.write bug_attachment.file_contents }
            if open(full_file_path).read != nil
              dispute_attachment = all_attachments.find {|attach| attach.id == bug_attachment.id}
              dispute_attachment.direct_upload_url = full_file_path
              dispute_attachment.save
            else
              morsel.output += "attachment #{bug_attachment.id} was blank, didn't save. investigate \n"
            end

          rescue
            morsel.output += "Failed to migration file with attachment id #{bug_attachment.id}...\n"
            morsel.output += "moving on...\n"
          end

        end
      rescue
        morsel.output += "Failed to successfully build bug with dispute id #{dispute_id}...\n"
        morsel.output += "moving on...\n"
      end

    end
    morsel.save
  end


end

namespace :bugs do
  task :update_in_summary_flag => :environment do
    bugs = Bug.all
    total = bugs.count
    puts "Starting update of #{total} bugs"
    bugs.each do |bug|
      total = total - 1
      next if bug.bugs_rules.empty?
      summary_sids = bug.summary_sids
      # cherry picked from load_rules_from_sids
      summary_sids.each do |ss|
        rule = Rule.find_or_load(ss)
        bug.rule_in_summary(rule) if rule
      end
      puts "#{bug.id} in summary flag updated, #{total} to go"
    end
  end


  task(:import_all).clear
  task :import_all, [:task_id, :run_at,:re_run, :current_user, :xmlrpc, :environment] do |t, args|

    desc "imports all bugs that were updated in the last 24 hours"

    Rails.logger.info "Importing bugs..."
    re_run = args[:re_run]
    run_at = args[:run_at]
    current_user = User.where(id: args[:current_user]).first
    # task = Task.where(id: args[:task_id]).first
    Rails.logger.info "Current user: #{current_user.display_name}"

    bug_ids_to_update = Bug.where("updated_at > ? ",(Time.now - 24.hours)).map{|a| a.id}
    # xmlrpc = args[:xmlrpc]
    # xmlrpc_token = xmlrpc.token

    # Rails.logger.info  "starting task ##{task.id}"
    # task_result = "We imported the following bugs:\n"


    bug_ids_to_update.each do |id|
      # task_result += "#{id}\n"
      Rails.logger.info  "importing bug #{id}"
      # xmlrpc_bug = Bugzilla::Bug.new(xmlrpc)
      # new_bug = xmlrpc_bug.get(id)
      # bug = Bug.bugzilla_import(current_user.id, xmlrpc_bug, xmlrpc_token, new_bug).first
    end

    # task.time_elapsed = (Time.now.to_f - task.created_at .to_f).round
    # task.completed = true
    # task.result = task_result
    # task.save

    # if re_run
    #   Task.schedule_task(task.task_type, run_at + 24.hours, re_run, current_user, xmlrpc)
    # end
  end

  task :import_all_bugs, [:bug_limit] => :environment do |t, args|

    puts "setting everything up.....\n"
    bug_limit = nil
    if args[:bug_limit].present?
      bug_limit = args[:bug_limit]
      if bug_limit.to_i.to_s != bug_limit
        raise "bug limit argument must be an integer"
      else
        bug_limit = bug_limit.to_i
      end
    end

    require 'thread'
    sema = Mutex.new
    current_user = User.where(:email => 'vrt-incoming@sourcefire.com').first

    #grab all the ids
    total_ids = []
    csv_text = File.read("public/bugzilla_snort_ids.csv")
    csv = CSV.parse(csv_text, :headers => true)
    csv.each do |row|
      total_ids << row["bug_id"].to_i
    end

    #filter out any that we already have
    current_ids = Bug.select("id").map {|bug| bug.id}

    total_ids = total_ids - current_ids
    total_ids = total_ids.sort.reverse

    #total_ids = total_ids.sort

    if bug_limit.present?
      total_ids = total_ids.first(bug_limit)
    end

    original_count = total_ids.size

    #troublesome bugs
    troubled_bugs = []

    #create a morsel
    global_morsel_added = Morsel.create({:output => "\n: Bugs attempting to be worked on: #{original_count}\n Added:\n"})
    global_morsel_rejected = Morsel.create({:output => "Errors:\n"})
    #some counters
    global_added = 0
    global_rejected = 0

    error_messages = []

    #start the timer
    time_start = Time.now

    puts "We have the bug ids, ok now we're starting....\n"

    threads = []

    7.times do |i|
      threads << Thread.new(i) do |tnum|

        thread_name = "[Thread #{tnum}]"

        #Couldn't use LoginSession here, was getting weird "circular load" errors
        login_session = login_to_bugzilla(current_user)
        xmlrpc_token = login_session

        xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
        xmlrpc.token = xmlrpc_token

        bugz = Bugzilla::Bug.new(xmlrpc)


        while true do
          new_bug = nil
          tid = nil
          if total_ids.blank?
            break
          else
            sema.synchronize do
              tid = total_ids.pop

            end
          end

          next if tid.blank?

          begin
            puts "#{thread_name} starting on id: #{tid}....\n"

            i = 0
            while i < 200
              begin
                new_bug = bugz.get(tid)
                break
              rescue
                login_session = login_to_bugzilla(current_user) #LoginSession.new(current_user).bugzilla_login
                xmlrpc_token = login_session

                xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
                xmlrpc.token = xmlrpc_token

                bugz = Bugzilla::Bug.new(xmlrpc)
                i = i + 1
                next
              end
            end

            importer = BugzillaImport.new
            whole_bug = importer.import(current_user, bugz, xmlrpc_token, new_bug).first if new_bug.present?
            if whole_bug.resolution.present? && (whole_bug.resolution == 'OPEN' || whole_bug.resolution == 'PENDING')
              begin
                options = {
                   :bug              => whole_bug,
                   :task_type        => Task::TASK_TYPE_PCAP_TEST,
                   :attachment_array => whole_bug.attachments.pcap.map{|a| a.id},
                }

                if options[:attachment_array].any?
                  new_task = Task.create(
                      :bug  => options[:bug],
                      :task_type     => options[:task_type],
                      :user => current_user
                  )

                  TestAttachment.new(new_task, xmlrpc_token, options[:attachment_array]).send_work_msg
                end

              rescue
                puts "\nsomething went wrong with testing #{tid}, but bug has been imported...so moving on\n"
              end
            end


            puts "\n#{tnum}------------------\nFinished bug with id: #{whole_bug.id}\n----------------\n\n"
            sema.synchronize do
              global_added += 1
              output = "###########################\nFinished importing bug: #{tid}\nTotal Bugs: #{original_count}\nBugs added so far: #{global_added}\nBugs rejected so far: #{global_rejected}\nBugs left: #{total_ids.size}\n###########################"
              global_morsel_added.output = output
              global_morsel_added.save
            end

          rescue
            puts "\n#{tnum}----------------\nsomething went wrong with id: #{tid}, so moving on.....\n-------------\n\n"
            sema.synchronize do
              global_rejected += 1
              output = "\n-----------------\nsomething went wrong with id: #{tid}, so moving on....\n"
              output += "-----------------\nbugs rejected so far: #{global_rejected}\nBugs left: #{total_ids.size}\n"
              error = ($!).to_s
              error_messages << error
              error_messages.uniq!
              output += "Types of errors seen so far:\n"
              output += error_messages.join("\n")
              output += "\n-----------------\n"
              global_morsel_rejected.output = output
              global_morsel_rejected.save

              troubled_bugs << tid

            end



          end

        end

        puts "#{thread_name} done"

      end

    end

    threads.each { |t| t.join }

    puts 'finished\n'
    time_end = Time.now

    time_total = time_end - time_start

    final_output = "\n\nFinished in #{time_total} seconds.\n"

    global_morsel_added.output += final_output
    global_morsel_added.save

    bad_ids_string = troubled_bugs.join(',')
    final_output_rejected = final_output
    final_output_rejected += "Rejected IDs:\n"
    final_output_rejected += "[#{bad_ids_string}]"
    global_morsel_rejected.output += final_output_rejected
    global_morsel_rejected.save
    puts final_output_rejected
    puts "total time: #{time_total}"
  end

  task :generate_giblets => :environment do
    successful_bug_count = 0
    failed_bug_count = 0
    failed_bugs = []

    Bug.all.each do |bug|
      puts "processing bug #{bug.id}....\n"
      begin
        parsed = bug.parse_summary #parsed sometimes fails...need to handle this
      rescue
        failed_bug_count += 1
        failed_bugs << "Bug: #{bug.id} failed in parse_summary"
        next
      end
      begin
        bug.load_whiteboard_values
      rescue
        failed_bug_count += 1
        failed_bugs << "Bug: #{bug.id} failed in load_whiteboard_values"
        next
      end

      begin
        bug.load_refs_from_summary(parsed[:refs], 'shallow')
        bug.load_giblets_from_refs
      rescue
        failed_bug_count += 1
        failed_bugs << "Bug: #{bug.id} failed in load_refs_from_summary"
        next
      end

      begin
        bug.load_tags_from_summary(parsed[:tags])
      rescue
        failed_bug_count += 1
        failed_bugs << "Bug: #{bug.id} failed in load_tags_from_summary"
        next
      end
      successful_bug_count += 1
    end

    report_blob = "Results of running Giblet Generation Backfill Task:\n\n"
    report_blob += "# of bugs successfully backfilled: #{successful_bug_count}\n"
    report_blob += "# of bugs that failed backfilling: #{failed_bug_count}\n"
    report_blob += "----------------------------------\n"
    report_blob += "Output Messages:\n"
    failed_bugs.each do |message|
      report_blob += "  #{message}\n"
    end
    report_blob += "----------------------------------\n"

    Morsel.create(:output => report_blob)

  end


  def login_to_bugzilla(current_user)
    bugzilla_username = Rails.configuration.bugzilla_username
    bugzilla_password = Rails.configuration.bugzilla_password

    Rails.logger.info("bugzilla: Using username: #{bugzilla_username}")
    if bugzilla_username && bugzilla_password
      @xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
      @xmlrpc.bugzilla_login(Bugzilla::User.new(@xmlrpc),
                             bugzilla_username,
                             bugzilla_password)
      Rails.logger.debug("bugzilla: Received xmlrpc token: #{@xmlrpc.token}")
      @xmlrpc_token = @xmlrpc.token
    else
      Rails.logger.error("bugzilla: Missing bugzilla_username or bugzilla_password.")
      raise "Missing bugzilla_username or bugzilla_password."
    end
  end


end
