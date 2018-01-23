class Schema2017end < ActiveRecord::Migration[5.1]
  def change
    create_table "attachments" do |t|
      t.timestamps
      t.integer "bugzilla_attachment_id"
      t.string "file_name"
      t.string "summary"
      t.string "content_type"
      t.string "direct_upload_url"
      t.integer "size", default: 0
      t.integer "creator"
      t.boolean "is_obsolete", default: false
      t.boolean "is_private", default: false
      t.boolean "minor_update", default: false
      t.integer "bug_id"
      t.integer "rule_id"
      t.integer "task_id"
      t.index ["bug_id"], name: "index_attachments_on_bug_id"
      t.index ["bugzilla_attachment_id"], name: "index_attachments_on_bugzilla_attachment_id"
      t.index ["rule_id"], name: "index_attachments_on_rule_id"
      t.index ["task_id"], name: "index_attachments_on_task_id"
    end

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
