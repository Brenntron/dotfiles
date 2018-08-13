class CreateComplaintEntryPreloads < ActiveRecord::Migration[5.1]
  def change
    create_table :complaint_entry_preloads do |t|
      t.integer         :complaint_entry_id
      t.text            :current_category_information
      t.text            :historic_category_information
      t.timestamps
    end
  end
end
