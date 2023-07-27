class AddReviewerFieldsToComplaintEntries < ActiveRecord::Migration[6.1]
  def change
    add_column :complaint_entries, :reviewer_id, :integer
    add_column :complaint_entries, :second_reviewer_id, :integer
  end
end
