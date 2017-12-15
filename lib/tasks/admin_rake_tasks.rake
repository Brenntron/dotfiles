require 'pry'
require 'rake'
namespace :bugs do
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

  task :import_all_bugs => :environment do
    require 'thread'
    sema = Mutex.new

    current_user = User.where(:email => 'vrt-incoming@sourcefire.com').first
    puts "setting everything up.....\n"

    #id_collect = [5068, 12171, 14781, 15319, 15841, 27822, 28079, 28082, 28778, 28909]

    id_collect = Bug.first(50).map {|b| b.id}

    #10 * 15 = 150 seconds
    #85 seconds with 3 threads
    #60 seconds with 5 threads


    #30 * 15 = 450 seconds
    #est for 3 threads 252 seconds   : #294   150 seconds
    #est for 5 threads 180 seconds   : 66 seconds

    #50 * 15 = 750 seconds
    #est for 3 threads 420 seconds
    #est for 5 threads 300 seconds    263 000
    #binding.pry
    time_start = Time.now

    #test bug
    #test_id = 5068
    #test2_id = 12171
    #need bugzilla auth 
    #login_session = LoginSession.new(current_user).bugzilla_login
    #xmlrpc_token = login_session

    #xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
    #xmlrpc.token = xmlrpc_token

    #bugz = Bugzilla::Bug.new(xmlrpc)
    puts "ok now we're starting....\n"
    #new_bug = bugz.get(test_id)
    #new_bug2 = bugz.get(test2_id)

    #login_session = login_to_bugzilla(current_user) #LoginSession.new(current_user).bugzilla_login
    #xmlrpc_token = login_session

    #xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
    #xmlrpc.token = xmlrpc_token

    #bugz = Bugzilla::Bug.new(xmlrpc)


    threads = []

    8.times do |i|
      threads << Thread.new(i) do |tnum|

        login_session = login_to_bugzilla(current_user) #LoginSession.new(current_user).bugzilla_login
        xmlrpc_token = login_session

        xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
        xmlrpc.token = xmlrpc_token

        bugz = Bugzilla::Bug.new(xmlrpc)


        while true do
          new_bug = nil
          tid = nil
          if id_collect.blank?
            break
          else
            sema.synchronize do
              tid = id_collect.pop

            end
          end

          next if tid.blank?

          begin
            puts "#{tnum}got one...starting on id: #{tid}....\n"
            #new_bug = bugz.get(tid)
            #sema.synchronize do
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
            #new_bug = bugz.get(tid)
            #end
            importer = BugzillaImport.new
            whole_bug = importer.import(current_user, bugz, xmlrpc_token, new_bug).first if new_bug.present? #Bug.bugzilla_import(current_user, bugz, xmlrpc_token, new_bug).first
            puts "\n#{tnum}------------------\nFinished bug with id: #{whole_bug.id}\n----------------\n\n"


          rescue
            puts "\n#{tnum}----------------\nsomething went wrong with id: #{tid}, so moving on.....\n-------------\n\n"
            puts $!
            puts $!.backtrace.join("\n")

          end



          #puts whole_bug.inspect

        end

        puts "#{tnum}Thread done"


      end
    end

    threads.each { |t| t.join }


    #t1.join
    #t2.join
    #t3.join
    #t4.join
    #t5.join

    #t6.join
    #t7.join
    #t8.join
    #t9.join
    #t10.join

    puts 'finished\n'

    time_end = Time.now

    time_total = time_end - time_start

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
