class AddSbFieldsToFileReputationDisputes < ActiveRecord::Migration[5.2]
  def change
    add_column :file_reputation_disputes, :resolution, :string
    add_column :file_reputation_disputes, :detection_name, :string
    add_column :file_reputation_disputes, :detection_created_at, :datetime
    add_column :file_reputation_disputes, :in_zoo, :boolean
    add_column :file_reputation_disputes, :assigned_id, :bigint
    add_column :file_reputation_disputes, :created_at, :datetime, null: false
    add_column :file_reputation_disputes, :updated_at, :datetime, null: false
    add_index :file_reputation_disputes, :assigned_id
    add_index :file_reputation_disputes, :created_at
    add_index :file_reputation_disputes, :updated_at
    change_column :file_reputation_disputes, :status, :string, null: false, default: 'NEW'
  end
end
