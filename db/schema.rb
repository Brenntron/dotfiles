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

ActiveRecord::Schema.define(version: 20170407152023) do

  create_table "alerts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "test_group",                  null: false
    t.integer  "rule_id",                     null: false
    t.integer  "attachment_id",               null: false
    t.float    "average_check",    limit: 24
    t.float    "average_match",    limit: 24
    t.float    "average_nonmatch", limit: 24
    t.index ["test_group", "attachment_id", "rule_id"], name: "index_alerts_on_test_group_and_attachment_id_and_rule_id", using: :btree
  end

  create_table "attachments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
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
    t.index ["bug_id"], name: "index_attachments_on_bug_id", using: :btree
    t.index ["bugzilla_attachment_id"], name: "index_attachments_on_bugzilla_attachment_id", using: :btree
    t.index ["reference_id"], name: "index_attachments_on_reference_id", using: :btree
    t.index ["rule_id"], name: "index_attachments_on_rule_id", using: :btree
    t.index ["task_id"], name: "index_attachments_on_task_id", using: :btree
  end

  create_table "attachments_exploits", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "attachment_id"
    t.integer "exploit_id"
  end

  create_table "attachments_rules", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "attachment_id"
    t.integer "rule_id"
  end

  create_table "bugs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
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
    t.index ["reference_id"], name: "index_bugs_on_reference_id", using: :btree
    t.index ["rule_id"], name: "index_bugs_on_rule_id", using: :btree
    t.index ["user_id"], name: "index_bugs_on_user_id", using: :btree
  end

  create_table "bugs_rules", primary_key: ["bug_id", "rule_id"], force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "bug_id",  default: 0, null: false
    t.integer "rule_id", default: 0, null: false
  end

  create_table "bugs_tags", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "bug_id", null: false
    t.integer "tag_id", null: false
    t.index ["bug_id", "tag_id"], name: "index_bugs_tags_on_bug_id_and_tag_id", unique: true, using: :btree
    t.index ["bug_id"], name: "index_bugs_tags_on_bug_id", using: :btree
    t.index ["tag_id"], name: "index_bugs_tags_on_tag_id", using: :btree
  end

  create_table "events", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "user"
    t.string   "action"
    t.string   "description"
    t.integer  "progress"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "exploit_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string  "name"
    t.string  "description"
    t.string  "pcap_validation"
    t.integer "exploit_id"
    t.index ["exploit_id"], name: "index_exploit_types_on_exploit_id", using: :btree
  end

  create_table "exploits", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "data"
    t.integer  "exploit_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "attachment_id"
    t.integer  "reference_id"
    t.index ["attachment_id"], name: "index_exploits_on_attachment_id", using: :btree
    t.index ["exploit_type_id"], name: "index_exploits_on_exploit_type_id", using: :btree
    t.index ["reference_id"], name: "index_exploits_on_reference_id", using: :btree
  end

  create_table "exploits_references", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "exploit_id"
    t.integer "reference_id"
  end

  create_table "notes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text     "comment",           limit: 65535
    t.string   "note_type"
    t.string   "author"
    t.integer  "notes_bugzilla_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bug_id"
    t.index ["bug_id"], name: "index_notes_on_bug_id", using: :btree
  end

  create_table "reference_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "description"
    t.string "validation"
    t.string "bugzilla_format"
    t.string "example"
    t.string "rule_format"
    t.string "url"
  end

  create_table "references", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "reference_data"
    t.integer  "reference_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["reference_type_id"], name: "index_references_on_reference_type_id", using: :btree
  end

  create_table "references_rules", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "reference_id"
    t.integer "rule_id"
    t.index ["reference_id"], name: "index_references_rules_on_reference_id", using: :btree
    t.index ["rule_id"], name: "index_references_rules_on_rule_id", using: :btree
  end

  create_table "roles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "role"
  end

  create_table "roles_users", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id", null: false
    t.integer "role_id", null: false
    t.index ["role_id"], name: "index_roles_users_on_role_id", using: :btree
    t.index ["user_id", "role_id"], name: "index_roles_users_on_user_id_and_role_id", unique: true, using: :btree
    t.index ["user_id"], name: "index_roles_users_on_user_id", using: :btree
  end

  create_table "rule_categories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "category"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rule_docs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "rule_id"
    t.text     "summary",           limit: 65535
    t.text     "impact",            limit: 65535
    t.text     "details",           limit: 65535
    t.text     "affected_sys",      limit: 65535
    t.text     "attack_scenarios",  limit: 65535
    t.text     "ease_of_attack",    limit: 65535
    t.text     "false_positives",   limit: 65535
    t.text     "false_negatives",   limit: 65535
    t.text     "corrective_action", limit: 65535
    t.text     "contributors",      limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["rule_id"], name: "index_rule_docs_on_rule_id", using: :btree
  end

  create_table "rules", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text     "rule_content",     limit: 65535
    t.text     "rule_parsed",      limit: 65535
    t.text     "rule_warnings",    limit: 65535
    t.text     "rule_failures",    limit: 65535
    t.text     "cvs_rule_content", limit: 65535
    t.text     "cvs_rule_parsed",  limit: 65535
    t.text     "connection",       limit: 65535
    t.string   "message"
    t.string   "flow"
    t.text     "detection",        limit: 65535
    t.string   "metadata"
    t.string   "class_type"
    t.integer  "gid"
    t.integer  "sid"
    t.integer  "rev"
    t.string   "state"
    t.float    "average_check",    limit: 24
    t.float    "average_match",    limit: 24
    t.float    "average_nonmatch", limit: 24
    t.boolean  "tested",                         default: false
    t.boolean  "committed",                      default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "task_id"
    t.integer  "rule_category_id"
    t.string   "filename"
    t.integer  "linenumber"
    t.string   "edit_status",                                    null: false
    t.boolean  "parsed",                         default: true,  null: false
    t.boolean  "on",                             default: true,  null: false
    t.string   "publish_status",                                 null: false
    t.index ["gid", "sid"], name: "index_rules_gid_and_sid", unique: true, using: :btree
    t.index ["rule_category_id"], name: "index_rules_on_rule_category_id", using: :btree
    t.index ["task_id"], name: "index_rules_on_task_id", using: :btree
  end

  create_table "tags", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tasks", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.boolean  "completed",                      default: false
    t.boolean  "failed",                         default: false
    t.text     "result",           limit: 65535
    t.string   "task_type"
    t.integer  "time_elapsed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bug_id"
    t.integer  "user_id"
    t.datetime "stats_updated_at"
    t.index ["bug_id"], name: "index_tasks_on_bug_id", using: :btree
    t.index ["user_id"], name: "index_tasks_on_user_id", using: :btree
  end

  create_table "test_reports", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "task_id",                     null: false
    t.integer  "rule_id",                     null: false
    t.float    "average_check",    limit: 24
    t.float    "average_match",    limit: 24
    t.float    "average_nonmatch", limit: 24
    t.index ["rule_id", "task_id"], name: "index_test_reports_on_rule_id_and_task_id", unique: true, using: :btree
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "cvs_username",                           null: false
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
    t.integer  "class_level",            default: 0,     null: false
    t.string   "authentication_token"
    t.integer  "metrics_timeframe",      default: 7
    t.integer  "parent_id"
    t.integer  "lft",                                    null: false
    t.integer  "rgt",                                    null: false
    t.integer  "depth",                  default: 0,     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["cvs_username"], name: "index_users_on_cvs_username", unique: true, using: :btree
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["lft"], name: "index_users_on_lft", using: :btree
    t.index ["parent_id"], name: "index_users_on_parent_id", using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    t.index ["rgt"], name: "index_users_on_rgt", using: :btree
  end

  create_table "versions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.string   "item_type",      limit: 191,        null: false
    t.integer  "item_id",                           null: false
    t.string   "event",                             null: false
    t.string   "whodunnit"
    t.text     "object",         limit: 4294967295
    t.text     "object_changes", limit: 4294967295
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
  end

end
