class CreateAlerts < ActiveRecord::Migration[5.0]
  def change
    create_table :alerts do |t|
      t.timestamps
      t.string :test_group, null: false
      t.integer :rule_id, null: false
      t.integer :attachment_id, null: false
      t.float :average_check
      t.float :average_match
      t.float :average_nonmatch
    end

    add_index :alerts, [:test_group, :attachment_id, :rule_id]
  end
end
