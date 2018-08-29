class AddWasDismissedToComplaintEntries < ActiveRecord::Migration[5.1]
  def change
    add_column :complaint_entries, :was_dismissed, :boolean, default: false
  end
end
