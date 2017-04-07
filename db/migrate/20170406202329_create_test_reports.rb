class CreateTestReports < ActiveRecord::Migration[5.0]
  def change
    create_table :test_reports do |t|
      t.timestamps
      t.integer :task_id, null: false
      t.integer :rule_id, null: false
      t.integer :bug_id
      t.float :average_check
      t.float :average_match
      t.float :average_nonmatch
    end

    add_index :test_reports, [:rule_id, :task_id], unique: true
  end
end
