class AddMetaData < ActiveRecord::Migration[5.2]
  def up
    add_column :disputes, :meta_data, :mediumtext
    add_column :complaints, :meta_data, :mediumtext
    add_column :file_reputation_disputes, :meta_data, :mediumtext
  end
end
