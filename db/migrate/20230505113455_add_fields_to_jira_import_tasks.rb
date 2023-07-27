class AddFieldsToJiraImportTasks < ActiveRecord::Migration[6.1]
  def change
    add_column :jira_import_tasks, :issue_summary, :text
    add_column :jira_import_tasks, :issue_description, :text
    add_column :jira_import_tasks, :issue_platform, :string
    add_column :jira_import_tasks, :issue_status, :string
  end
end
