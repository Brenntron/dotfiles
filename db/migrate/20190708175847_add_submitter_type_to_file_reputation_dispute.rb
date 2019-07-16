class AddSubmitterTypeToFileReputationDispute < ActiveRecord::Migration[5.2]
  def change
    add_column :file_reputation_disputes, :submitter_type, :string
  end
end
