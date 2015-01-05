class CreateBugs < ActiveRecord::Migration
  def change
    create_table :bugs do |t|
      t.integer :bugzilla_id
      t.string :state
      t.string :summary
      t.integer :committer_id
      t.integer :gid, :default => 1
      t.integer :sid
      t.integer :rev, :default => 1
      t.text :notes
      t.text :committer_notes
      t.timestamps
    end
    add_reference :bugs, :user, index: true
    add_reference :bugs, :reference, index: true
    add_reference :bugs, :rule, index: true
    add_reference :bugs, :attachment
  end
end

