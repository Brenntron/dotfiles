require 'rake'

namespace :jira do
  desc 'Import issues from Jira'
  task :import => :environment do
    filters = ['status != Resolved', "issuetype != 'Question / Assistance'", 'createdDate > -30d']
    project_key = Rails.configuration.jira.project_key
    project = JiraRest::Project.new(project_key)
    platform_field_id = project.custom_fields[:platform]
    issues = project.issues(filters)
    issues.each do |issue|
      next if issue.fields.dig(platform_field_id, 'value') == "OpenDNS"

      import_task = JiraImportTask.find_by(issue_key: issue.key)

      if import_task.present?
        if import_task.status == JiraImportTask::STATUS_PENDING && import_task.updated_at < 6.hours.ago
          import_task.process_import
        end
        next
      end
      
      task_attributes = {
        issue_key: issue.key,
        submitter: issue.reporter.name,
        status: JiraImportTask::STATUS_PENDING,
        issue_summary: issue.summary,
        issue_status: issue.status.name,
        issue_description: issue.description,
        issue_platform: issue.fields.dig(platform_field_id, 'value'),
        issue_type: issue.issuetype.name
      }
      import_task = JiraImportTask.create!(task_attributes)
      import_task.process_import
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
