class IncreaseUrlPrimaryCategorySizeInComplaintEntries < ActiveRecord::Migration[5.2]
  def change
    change_column :complaint_entries, :url_primary_category, :string, :limit => 1000
  end
end
