class RenameSubmitterTypeToSandboxKey < ActiveRecord::Migration[5.2]
  def change
    rename_column :file_reputation_disputes, :submitter_type, :sandbox_key
  end
end
