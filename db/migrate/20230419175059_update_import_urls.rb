class UpdateImportUrls < ActiveRecord::Migration[6.1]
  def change
    add_column    :import_urls, :complaint_id, :integer
    add_column    :import_urls, :verdict_reason, :string
    rename_column :import_urls, :bast_status, :bast_verdict
  end
end
