class CreateJoinTableBugsWhiteboards < ActiveRecord::Migration[5.1]
  def change
    create_join_table :bugs, :whiteboards do |t|
      t.index :bug_id
      t.index :whiteboard_id
    end
    add_index :bugs_whiteboards, [:bug_id, :whiteboard_id], :unique => true
  end
end
