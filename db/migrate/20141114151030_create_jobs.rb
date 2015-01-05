class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.boolean  "completed",   :default => false
      t.boolean  "failed",      :default => false
      t.text     "result"
      t.string  "job_type"
      t.timestamps
    end
    add_reference :jobs, :bug, index: true
    add_reference :jobs, :user, index: true
  end
end
