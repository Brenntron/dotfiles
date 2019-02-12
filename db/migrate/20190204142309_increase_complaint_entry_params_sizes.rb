class IncreaseComplaintEntryParamsSizes < ActiveRecord::Migration[5.2]
  def change
    change_column :complaint_entries, :category, :string, :limit => 2000
    change_column :complaint_entries, :url_primary_category, :string, :limit => 2000
  end
end
