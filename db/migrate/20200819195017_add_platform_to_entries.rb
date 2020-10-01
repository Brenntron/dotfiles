class AddPlatformToEntries < ActiveRecord::Migration[5.2]
  def change
    add_column :dispute_entries, :platform, :string
    add_column :complaint_entries, :platform, :string
  end
end
