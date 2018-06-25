class CreateDisputeComments < ActiveRecord::Migration[5.1]
  def change
    create_table :dispute_comments do |t|
      t.integer       :dispute_id
      t.text          :comment
      t.integer       :user_id
      t.timestamps
    end
  end
end
