class Schema2017 < ActiveRecord::Migration[5.1]
  def change
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
  end
end
