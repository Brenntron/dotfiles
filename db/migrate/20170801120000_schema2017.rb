class Schema2017 < ActiveRecord::Migration[5.1]
  def change
    create_table "bugs_rules", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "bug_id", default: 0, null: false
      t.integer "rule_id", default: 0, null: false
      t.text "svn_result_output"
      t.integer "svn_result_code"
      t.index ["bug_id", "rule_id"], name: "index_bugs_rules_on_bug_id_and_rule_id", unique: true
    end

    create_table "rules", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
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

    create_table "tasks", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
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
  end
end
