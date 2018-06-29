class CreateComplaintMarkedCommits < ActiveRecord::Migration[5.1]
  def change
    create_table :complaint_marked_commits do |t|
      t.timestamps
      t.integer :user_id
      t.integer :complaint_entry_id
      t.string :comment
      t.string :category_list
    end
  end
end
