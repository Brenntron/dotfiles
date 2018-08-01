class AddRelatedAtToDisputes < ActiveRecord::Migration[5.1]
  def change
    add_column :disputes, :related_at, :datetime
  end
end
