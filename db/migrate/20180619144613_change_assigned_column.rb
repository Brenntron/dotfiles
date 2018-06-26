class ChangeAssignedColumn < ActiveRecord::Migration[5.1]
  def change
    add_column :disputes, :user_id, :integer
    remove_column :disputes, :assigned_to
  end
end
