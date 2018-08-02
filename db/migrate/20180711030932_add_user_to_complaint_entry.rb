class AddUserToComplaintEntry < ActiveRecord::Migration[5.1]
  def change
    add_column :complaint_entries, :user_id, :integer
    remove_column :complaints, :user_id, :integer
  end
end
