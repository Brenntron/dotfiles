require 'pry'
require 'rake'

namespace :escalations do
  task :check_file_reputations do
    FileReputationDispute.check_for_rep_updates
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
