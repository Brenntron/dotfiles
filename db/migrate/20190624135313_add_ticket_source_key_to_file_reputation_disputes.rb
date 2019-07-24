class AddTicketSourceKeyToFileReputationDisputes < ActiveRecord::Migration[5.2]
  def change
    add_column :file_reputation_disputes, :ticket_source_key, :integer
  end
end
