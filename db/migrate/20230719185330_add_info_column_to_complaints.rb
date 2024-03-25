class AddInfoColumnToComplaints < ActiveRecord::Migration[6.1]
  def change
    add_column :complaint_entries, :abuse_information, :text
  end
end
