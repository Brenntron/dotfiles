class AddRelatedToDisputes < ActiveRecord::Migration[5.1]
  def change
    add_column :disputes, :related_id, :integer
  end
end
