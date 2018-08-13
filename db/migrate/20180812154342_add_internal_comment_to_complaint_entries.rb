class AddInternalCommentToComplaintEntries < ActiveRecord::Migration[5.1]
  def change
    add_column :complaint_entries, :internal_comment, :text
  end
end
