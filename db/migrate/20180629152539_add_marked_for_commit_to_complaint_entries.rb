class AddMarkedForCommitToComplaintEntries < ActiveRecord::Migration[5.1]
  def change
    add_column :complaint_entries, :marked_for_commit, :boolean, default: false
  end
end
