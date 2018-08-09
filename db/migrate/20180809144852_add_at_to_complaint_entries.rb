class AddAtToComplaintEntries < ActiveRecord::Migration[5.1]
  def change
    add_column :complaint_entries, :complaint_assigned_at, :datetime
    add_column :complaint_entries, :complaint_closed_at, :datetime
  end
end
