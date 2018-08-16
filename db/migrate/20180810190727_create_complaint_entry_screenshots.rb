class CreateComplaintEntryScreenshots < ActiveRecord::Migration[5.1]
  def change
    create_table :complaint_entry_screenshots do |table|
      table.timestamps
      table.integer :complaint_entry_id
      table.binary :screenshot, :limit => 10.megabyte
    end
    add_index :complaint_entry_screenshots, :complaint_entry_id
  end
end
