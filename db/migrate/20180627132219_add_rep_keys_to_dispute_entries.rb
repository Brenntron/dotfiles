class AddRepKeysToDisputeEntries < ActiveRecord::Migration[5.1]
  def change
    add_column :dispute_entries, :webrep_wlbl_key, :integer
    add_column :dispute_entries, :reptool_key, :integer
  end
end
