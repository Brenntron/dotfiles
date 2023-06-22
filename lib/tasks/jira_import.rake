require 'rake'

namespace :jira do
  desc 'Import issues from Jira'
  task :import => :environment do
    JiraImportTask.queue_imports
  end

  desc 'Create complaint tickets based on response from Bast'
  task :make_complaints => :environment do
    tasks = JiraImportTask.where(status: JiraImportTask::STATUS_AWAITING_BAST_VERDICT)
    tasks.each do |task|
      task.create_tickets
    end
  end
end
