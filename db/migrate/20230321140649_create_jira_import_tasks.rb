class CreateJiraImportTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :jira_import_tasks do |t|
      t.string      :issue_key, null: false, unique: true
      t.string      :status
      t.string      :result
      t.string      :submitter
      t.integer     :bast_task, unique: true
      t.datetime    :imported_at
      t.timestamps
    end
  end
end
