# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161021150451) do

  create_table "attachments", force: true do |t|
    t.integer  "bugzilla_attachment_id"
    t.string   "file_name"
    t.string   "summary"
    t.string   "content_type"
    t.string   "direct_upload_url"
    t.integer  "size",                   default: 0
    t.integer  "creator"
    t.boolean  "is_obsolete",            default: false
    t.boolean  "is_private",             default: false
    t.boolean  "minor_update",           default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bug_id"
    t.integer  "rule_id"
    t.integer  "reference_id"
    t.integer  "task_id"
  end

  add_index "attachments", ["bug_id"], name: "index_attachments_on_bug_id", using: :btree
  add_index "attachments", ["bugzilla_attachment_id"], name: "index_attachments_on_bugzilla_attachment_id", using: :btree
  add_index "attachments", ["reference_id"], name: "index_attachments_on_reference_id", using: :btree
  add_index "attachments", ["rule_id"], name: "index_attachments_on_rule_id", using: :btree
  add_index "attachments", ["task_id"], name: "index_attachments_on_task_id", using: :btree

  create_table "attachments_exploits", force: true do |t|
    t.integer "attachment_id"
    t.integer "exploit_id"
  end

  create_table "attachments_rules", id: false, force: true do |t|
    t.integer "attachment_id"
    t.integer "rule_id"
  end

  create_table "bugs", force: true do |t|
    t.integer  "bugzilla_id"
    t.string   "state"
    t.string   "status"
    t.string   "resolution"
    t.string   "creator"
    t.string   "summary"
    t.integer  "committer_id"
    t.string   "product"
    t.string   "component"
    t.string   "version"
    t.string   "description"
    t.string   "opsys"
    t.string   "platform"
    t.string   "priority"
    t.string   "severity"
    t.string   "research_notes"
    t.string   "committer_notes"
    t.integer  "classification",  default: 0
    t.integer  "gid",             default: 1
    t.integer  "sid"
    t.integer  "rev",             default: 1
    t.datetime "assigned_at"
    t.datetime "pending_at"
    t.datetime "resolved_at"
    t.datetime "reopened_at"
    t.integer  "work_time"
    t.integer  "review_time"
    t.integer  "rework_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "reference_id"
    t.integer  "rule_id"
    t.integer  "attachment_id"
  end

  add_index "bugs", ["reference_id"], name: "index_bugs_on_reference_id", using: :btree
  add_index "bugs", ["rule_id"], name: "index_bugs_on_rule_id", using: :btree
  add_index "bugs", ["user_id"], name: "index_bugs_on_user_id", using: :btree

  create_table "bugs_rules", id: false, force: true do |t|
    t.integer "bug_id",  default: 0, null: false
    t.integer "rule_id", default: 0, null: false
  end

  create_table "bugs_tags", id: false, force: true do |t|
    t.integer "bug_id", null: false
    t.integer "tag_id", null: false
  end

  add_index "bugs_tags", ["bug_id", "tag_id"], name: "index_bugs_tags_on_bug_id_and_tag_id", unique: true, using: :btree
  add_index "bugs_tags", ["bug_id"], name: "index_bugs_tags_on_bug_id", using: :btree
  add_index "bugs_tags", ["tag_id"], name: "index_bugs_tags_on_tag_id", using: :btree

  create_table "events", force: true do |t|
    t.string   "user"
    t.string   "action"
    t.string   "description"
    t.integer  "progress"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "exploit_types", force: true do |t|
    t.string  "name"
    t.string  "description"
    t.string  "pcap_validation"
    t.integer "exploit_id"
  end

  add_index "exploit_types", ["exploit_id"], name: "index_exploit_types_on_exploit_id", using: :btree

  create_table "exploits", force: true do |t|
    t.string   "data"
    t.integer  "exploit_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "attachment_id"
    t.integer  "reference_id"
  end

  add_index "exploits", ["attachment_id"], name: "index_exploits_on_attachment_id", using: :btree
  add_index "exploits", ["exploit_type_id"], name: "index_exploits_on_exploit_type_id", using: :btree
  add_index "exploits", ["reference_id"], name: "index_exploits_on_reference_id", using: :btree

  create_table "exploits_references", force: true do |t|
    t.integer "exploit_id"
    t.integer "reference_id"
  end

  create_table "notes", force: true do |t|
    t.text     "comment"
    t.string   "note_type"
    t.string   "author"
    t.integer  "notes_bugzilla_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bug_id"
  end

  add_index "notes", ["bug_id"], name: "index_notes_on_bug_id", using: :btree

  create_table "reference_types", force: true do |t|
    t.string  "name"
    t.string  "description"
    t.string  "validation"
    t.string  "bugzilla_format"
    t.string  "example"
    t.string  "rule_format"
    t.string  "url"
    t.integer "reference_id"
  end

  add_index "reference_types", ["reference_id"], name: "index_reference_types_on_reference_id", using: :btree

  create_table "references", force: true do |t|
    t.string   "reference_data"
    t.integer  "reference_type_id"
    t.integer  "bug_id"
    t.integer  "exploit_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "references", ["bug_id"], name: "index_references_on_bug_id", using: :btree
  add_index "references", ["exploit_id"], name: "index_references_on_exploit_id", using: :btree
  add_index "references", ["reference_type_id"], name: "index_references_on_reference_type_id", using: :btree

  create_table "references_rules", id: false, force: true do |t|
    t.integer "reference_id"
    t.integer "rule_id"
  end

  add_index "references_rules", ["reference_id"], name: "index_references_rules_on_reference_id", using: :btree
  add_index "references_rules", ["rule_id"], name: "index_references_rules_on_rule_id", using: :btree

  create_table "relationships", force: true do |t|
    t.integer  "user_id"
    t.integer  "team_member_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rule_categories", force: true do |t|
    t.string   "category"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rules", force: true do |t|
    t.text     "rule_content"
    t.text     "rule_parsed"
    t.text     "rule_warnings"
    t.text     "rule_failures"
    t.text     "cvs_rule_content"
    t.text     "cvs_rule_parsed"
    t.string   "connection"
    t.string   "message"
    t.string   "flow"
    t.text     "detection"
    t.string   "metadata"
    t.string   "class_type"
    t.integer  "gid"
    t.integer  "sid"
    t.integer  "rev"
    t.string   "state"
    t.float    "average_check",    limit: 24
    t.float    "average_match",    limit: 24
    t.float    "average_nonmatch", limit: 24
    t.boolean  "tested",                      default: false
    t.boolean  "committed",                   default: false
    t.string   "documentation"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "task_id"
    t.integer  "rule_category_id"
  end

  add_index "rules", ["gid", "sid"], name: "index_rules_on_gid_and_sid", unique: true, using: :btree
  add_index "rules", ["rule_category_id"], name: "index_rules_on_rule_category_id", using: :btree
  add_index "rules", ["task_id"], name: "index_rules_on_task_id", using: :btree

  create_table "tags", force: true do |t|
    t.string   "name",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tasks", force: true do |t|
    t.boolean  "completed",    default: false
    t.boolean  "failed",       default: false
    t.text     "result"
    t.string   "task_type"
    t.integer  "time_elapsed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bug_id"
    t.integer  "user_id"
  end

  add_index "tasks", ["bug_id"], name: "index_tasks_on_bug_id", using: :btree
  add_index "tasks", ["user_id"], name: "index_tasks_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "cvs_username"
    t.string   "cec_username"
    t.string   "kerberos_login"
    t.string   "display_name"
    t.boolean  "committer",              default: false
    t.boolean  "confirmed",              default: false
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "role"
    t.integer  "class_level"
    t.string   "authentication_token"
    t.integer  "metrics_timeframe",      default: 7
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bug_id"
  end

  add_index "users", ["bug_id"], name: "index_users_on_bug_id", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
