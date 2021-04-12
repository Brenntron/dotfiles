class AddLoggingToDisputes < ActiveRecord::Migration[5.2]
  def up
    add_column :disputes, :bridge_packet, :mediumtext
    add_column :disputes, :import_log, :mediumtext

    add_column :complaints, :bridge_packet, :mediumtext
    add_column :complaints, :import_log, :mediumtext

    add_column :file_reputation_disputes, :bridge_packet, :mediumtext
    add_column :file_reputation_disputes, :import_log, :mediumtext
  end
end
