class AddRespondedAtToDisputes < ActiveRecord::Migration[5.1]
  def change
    add_column :disputes, :case_responded_at, :datetime
  end
end
