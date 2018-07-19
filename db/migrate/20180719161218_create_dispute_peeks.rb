class CreateDisputePeeks < ActiveRecord::Migration[5.1]
  def change
    create_table :dispute_peeks do |t|
      t.timestamps
      t.integer :user_id
      t.integer :dispute_id
    end
    add_index :dispute_peeks, [:user_id, :dispute_id], unique: true
  end
end
