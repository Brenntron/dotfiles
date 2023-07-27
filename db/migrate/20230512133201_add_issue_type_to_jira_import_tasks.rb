class AddIssueTypeToJiraImportTasks < ActiveRecord::Migration[6.1]
  def change
    add_column :jira_import_tasks, :issue_type, :string
  end
end
