class CreateBugBlockers < ActiveRecord::Migration[5.1]
  def change
    create_table :bug_blockers do |t|
      t.integer    :snort_blocker_bug_id
      t.integer    :snort_blocked_bug_id
      t.timestamps
    end
  end
end
