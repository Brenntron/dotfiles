class AddCategoryToComplaintEntries < ActiveRecord::Migration[5.1]
  def change
    add_column :complaint_entries, :category, :string
  end
end
