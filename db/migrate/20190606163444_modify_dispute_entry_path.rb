class ModifyDisputeEntryPath < ActiveRecord::Migration[5.2]
  def change
    change_column :dispute_entries, :path, :text
    change_column :complaint_entries, :path, :text
  end
end
