class IncreaseCategorySizeInComplaintEntries < ActiveRecord::Migration[5.2]
  def change
    change_column :complaint_entries, :category, :string, :limit => 1000
  end
end
