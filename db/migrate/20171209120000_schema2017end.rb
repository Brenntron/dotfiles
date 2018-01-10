class Schema2017end < ActiveRecord::Migration[5.1]
  def change
    create_table "bugs" do |t|
      t.timestamps
      t.integer "bugzilla_id"
      t.string "state"
      t.string "status"
      t.string "resolution"
      t.string "creator"
      t.text "summary"
      t.integer "committer_id"
      t.string "product"
      t.string "component"
      t.string "version"
      t.text "description"
      t.string "opsys"
      t.string "platform"
      t.string "priority"
      t.string "severity"
      t.text "research_notes"
      t.string "committer_notes"
      t.integer "classification", default: 0
      t.datetime "assigned_at"
      t.datetime "pending_at"
      t.datetime "resolved_at"
      t.datetime "reopened_at"
      t.integer "work_time"
      t.integer "review_time"
      t.integer "rework_time"
      t.integer "user_id"
      t.string "liberty", default: "CLEAR"
      t.string "whiteboard"
      t.index ["user_id"], name: "index_bugs_on_user_id"
    end

  end
end
