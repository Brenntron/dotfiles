require 'rake'

namespace :jira do
  desc 'Import issues from Jira'
  task :import => :environment do
    filters = ['statusCategory != Done', 'createdDate > -30d']

    project_key = Rails.configuration.jira.project_key
    project = JiraRest::Project.new(project_key)
    issues = project.issues(filters)

    issues.each do |issue|
      import_task = JiraImportTask.find_by(issue_key: issue.key)
      if import_task.present?
        next
      else
        import_task = JiraImportTask.create!(issue_key: issue.key, submitter: issue.reporter.name, status: JiraImportTask::STATUS_PENDING)
        import_task.process_import
      end
    end
  end

  desc 'Create complaint tickets based on response from Bast'
  task :make_complaints => :environment do
    tasks = JiraImportTask.where(status: JiraImportTask::STATUS_AWAITING_BAST_VERDICT)
    tasks.each do |task|
      task.create_tickets
    end
  end
end
