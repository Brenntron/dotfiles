class CreateJoinTableReferencesBugs < ActiveRecord::Migration[5.0]
  def change
    create_join_table :references, :bugs do |t|
      t.index :bug_id
      t.index :reference_id
    end
    add_index :bugs_references, [:bug_id, :reference_id], :unique => true
  end
end
