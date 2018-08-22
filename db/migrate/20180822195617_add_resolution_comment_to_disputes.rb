class AddResolutionCommentToDisputes < ActiveRecord::Migration[5.1]
  def change
    add_column :disputes, :resolution_comment, :text
  end
end
