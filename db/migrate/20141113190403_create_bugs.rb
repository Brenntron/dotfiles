class CreateBugs < ActiveRecord::Migration
  def change
    create_table :bugs do |t|
      t.integer :bugzilla_id
      t.string  :state
      t.string  :creator
      t.string  :summary
      t.integer :committer_id
      t.string  :product
      t.string  :component
      t.string  :version
      t.string  :description
      t.string  :opsys
      t.string  :platform
      t.string  :priority
      t.string  :severity
      t.integer :gid, :default => 1
      t.integer :sid
      t.integer :rev, :default => 1
      t.text    :committer_notes
      t.timestamps
    end
    add_reference :bugs, :notes, index: true
    add_reference :bugs, :user, index: true
    add_reference :bugs, :reference, index: true
    add_reference :bugs, :rule, index: true
    add_reference :bugs, :attachment
  end
end

