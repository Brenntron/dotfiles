class CreateJoinTableBugsTags < ActiveRecord::Migration[4.2]
  def change
    create_join_table :bugs, :tags do |t|
      t.index :bug_id
      t.index :tag_id
    end
    add_index :bugs_tags, [:bug_id, :tag_id], :unique => true
  end
end
