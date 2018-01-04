class Schema2017 < ActiveRecord::Migration[5.1]
  def change
    create_table "alerts" do |t|
      t.timestamps
      t.string "test_group", null: false
      t.integer "rule_id", null: false
      t.integer "attachment_id", null: false
      t.index ["test_group", "attachment_id", "rule_id"], name: "index_alerts_on_test_group_and_attachment_id_and_rule_id"
    end

    create_table "bugs_rules" do |t|
      t.timestamps
      t.integer "bug_id", default: 0, null: false
      t.integer "rule_id", default: 0, null: false
      t.text "svn_result_output"
      t.integer "svn_result_code"
      t.index ["bug_id", "rule_id"], name: "index_bugs_rules_on_bug_id_and_rule_id", unique: true
    end

    create_table "bugs_tags" do |t|
      t.integer "bug_id", null: false
      t.integer "tag_id", null: false
      t.index ["bug_id", "tag_id"], name: "index_bugs_tags_on_bug_id_and_tag_id", unique: true
      t.index ["bug_id"], name: "index_bugs_tags_on_bug_id"
      t.index ["tag_id"], name: "index_bugs_tags_on_tag_id"
    end

    create_table "exploits_references" do |t|
      t.integer "exploit_id"
      t.integer "reference_id"
    end

    create_table "events" do |t|
      t.timestamps
      t.string "user"
      t.string "action"
      t.string "description"
      t.integer "progress"
    end

    create_table "reference_types" do |t|
      t.string "name"
      t.string "description"
      t.string "validation"
      t.string "bugzilla_format"
      t.string "example"
      t.string "rule_format"
      t.string "url"
    end

    create_table "rule_categories" do |t|
      t.timestamps
      t.string "category"
    end

    create_table "rules" do |t|
      t.timestamps
      t.integer "gid"
      t.integer "sid"
      t.integer "rev"
      t.string "filename"
      t.integer "linenumber"
      t.text "rule_content"
      t.text "rule_parsed"
      t.text "rule_warnings"
      t.text "rule_failures"
      t.text "cvs_rule_content"
      t.text "cvs_rule_parsed"
      t.text "connection"
      t.string "message"
      t.string "flow"
      t.text "detection"
      t.string "metadata"
      t.string "class_type"
      t.bigint "task_id"
      t.bigint "rule_category_id"
      t.string "state"
      t.string "edit_status", null: false
      t.boolean "parsed", default: true, null: false
      t.boolean "on", default: true, null: false
      t.string "publish_status", null: false
      t.boolean "tested", default: false
      t.boolean "committed", default: false
      t.index ["gid", "sid"], name: "index_rules_gid_and_sid", unique: true
      t.index ["rule_category_id"], name: "index_rules_on_rule_category_id"
      t.index ["task_id"], name: "index_rules_on_task_id"
    end

    create_table "tasks", id: :integer do |t|
      t.timestamps
      t.boolean "completed", default: false
      t.boolean "failed", default: false
      t.text "result"
      t.bigint "user_id"
      t.bigint "bug_id"
      t.string "task_type"
      t.integer "time_elapsed"
      t.datetime "stats_updated_at"
      t.index ["bug_id"], name: "index_tasks_on_bug_id"
      t.index ["user_id"], name: "index_tasks_on_user_id"
    end

    create_table "test_reports" do |t|
      t.timestamps
      t.integer "task_id", null: false
      t.integer "rule_id", null: false
      t.integer "bug_id"
      t.float "average_check", limit: 24
      t.float "average_match", limit: 24
      t.float "average_nonmatch", limit: 24
      t.index ["rule_id", "task_id"], name: "index_test_reports_on_rule_id_and_task_id", unique: true
    end
  end
end
