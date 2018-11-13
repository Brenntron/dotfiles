class AddStatusCommentToDisputes < ActiveRecord::Migration[5.1]
  def change
    add_column :disputes, :status_comment, :text
  end
end
