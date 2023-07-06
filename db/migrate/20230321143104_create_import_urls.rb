class CreateImportUrls < ActiveRecord::Migration[5.2]
  def change
    create_table :import_urls do |t|
      t.integer    :jira_import_task_id
      t.string     :submitted_url
      t.string     :domain
      t.string     :bast_status
      t.timestamps
    end
  end
end
