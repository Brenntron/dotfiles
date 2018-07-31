class RemoveTagsFromComplaints < ActiveRecord::Migration[5.1]
  def change
    remove_column :complaints, :tag, :string
    remove_column :complaint_entries, :tag, :string
  end
end
