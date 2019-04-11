class FileRepComments < ActiveRecord::Migration[5.2]
  def change
    create_table :file_rep_comments do |t|
      t.timestamps
      t.string :file_reputation_dispute_id
      t.text :comment
      t.integer :user_id
    end
  end
end
