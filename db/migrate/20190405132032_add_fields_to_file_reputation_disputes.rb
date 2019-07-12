class AddFieldsToFileReputationDisputes < ActiveRecord::Migration[5.2]
  def change
    rename_table :file_reputation_tickets, :file_reputation_disputes
    add_column :file_reputation_disputes, :file_name, :string
    add_column :file_reputation_disputes, :file_size, :integer
    add_column :file_reputation_disputes, :sha256_hash, :string
    add_column :file_reputation_disputes, :sample_type, :string
    add_column :file_reputation_disputes, :disposition, :string
    add_column :file_reputation_disputes, :disposition_suggested, :string
    add_column :file_reputation_disputes, :sandbox_score, :float
    add_column :file_reputation_disputes, :sandbox_threshold, :float
    add_column :file_reputation_disputes, :sandbox_signer, :string
    add_column :file_reputation_disputes, :threatgrid_score, :float
    add_column :file_reputation_disputes, :threatgrid_threshold, :float
    add_column :file_reputation_disputes, :threatgrid_signer, :string
    add_column :file_reputation_disputes, :reversing_labs_score, :float
    add_column :file_reputation_disputes, :reversing_labs_signer, :string
    remove_column :file_reputation_disputes, :reputation_file_id, :bigint
    add_index :file_reputation_disputes, :sha256_hash
  end
end
