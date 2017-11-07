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
    task = Task.where(id: args[:task_id]).first
    Rails.logger.info "Current user: #{current_user.display_name}"

    bug_ids_to_update = Bug.where("updated_at > ? ",(Time.now - 24.hours)).map{|a| a.id}
    xmlrpc = args[:xmlrpc]
    xmlrpc_token = xmlrpc.token

    Rails.logger.info  "starting task ##{task.id}"
    task_result = "We imported the following bugs:\n"


    bug_ids_to_update.each do |id|
      task_result += "#{id}\n"
      Rails.logger.info  "importing bug #{id}"
      xmlrpc_bug = Bugzilla::Bug.new(xmlrpc)
      new_bug = xmlrpc_bug.get(id)
      bug = Bug.bugzilla_import(current_user.id, xmlrpc_bug, xmlrpc_token, new_bug).first
    end

    task.time_elapsed = (Time.now.to_f - task.created_at .to_f).round
    task.completed = true
    task.result = task_result
    task.save

    # if re_run
    #   Task.schedule_task(task.task_type, run_at + 24.hours, re_run, current_user, xmlrpc)
    # end
  end



end
