class AddRespondedToFileReputationDisputes < ActiveRecord::Migration[5.2]
  def change
    add_column :file_reputation_disputes, :case_responded_at, :datetime
  end
end
