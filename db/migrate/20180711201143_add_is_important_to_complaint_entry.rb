class AddIsImportantToComplaintEntry < ActiveRecord::Migration[5.1]
  def change
    add_column :complaint_entries, :is_important, :boolean
  end
end