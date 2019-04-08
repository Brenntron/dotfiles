class AddUserIdToFileRep < ActiveRecord::Migration[5.2]
  def change
    add_column :file_reps, :user_id, :bigint
  end
end
