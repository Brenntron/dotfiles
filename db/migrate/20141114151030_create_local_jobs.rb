class CreateLocalJobs < ActiveRecord::Migration
  def change
    create_table :local_jobs do |t|
      t.boolean  "completed",   :default => false
      t.boolean  "failed",      :default => false
      t.text     "result"
      t.string  "job_type"
      t.integer "time_elapsed"
      t.timestamps
    end
    add_reference :local_jobs, :bug, index: true
    add_reference :local_jobs, :user, index: true
    
  end
end
