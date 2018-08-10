class AddAtToComplaintEntries < ActiveRecord::Migration[5.1]
  def change
    add_column :complaint_entries, :case_resolved_at, :datetime
    add_column :complaint_entries, :case_assigned_at, :datetime
  end
end
