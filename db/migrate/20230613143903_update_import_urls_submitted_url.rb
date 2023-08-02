class UpdateImportUrlsSubmittedUrl < ActiveRecord::Migration[6.1]
  def change
    change_column :import_urls, :submitted_url, :text
  end
end
