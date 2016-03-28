class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.boolean  "completed",   :default => false
      t.boolean  "failed",      :default => false
      t.text     "result"
      t.string  "task_type"
      t.integer "time_elapsed"
      t.timestamps
    end
    add_reference :tasks, :bug, index: true
    add_reference :tasks, :user, index: true
    
  end
end
