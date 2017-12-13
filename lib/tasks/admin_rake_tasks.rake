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
    current_user = User.where(:email => 'vrt-incoming@sourcefire.com').first


    #test bug
    test_id = 5068

    #need bugzilla auth 
    login_session = LoginSession.new(current_user).bugzilla_login
    xmlrpc_token = login_session

    xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
    xmlrpc.token = xmlrpc_token

    bugz = Bugzilla::Bug.new(xmlrpc)

    new_bug = bugz.get(test_id)

    whole_bug = Bug.bugzilla_import(current_user, bugz, xmlrpc_token, new_bug).first

    puts whole_bug.inspect
    
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

end
