class AddPlatformIdToTickets < ActiveRecord::Migration[5.2]
  def up
    add_column :dispute_entries, :platform_id, :integer
    add_column :complaint_entries, :platform_id, :integer
    add_column :file_reputation_disputes, :platform_id, :integer
    add_column :disputes, :platform_id, :integer
    add_column :complaints, :platform_id, :integer
  end
end
