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

ActiveRecord::Schema.define(version: 20171205164129) do

  create_table "alerts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "test_group", null: false
    t.integer "rule_id", null: false
    t.integer "attachment_id", null: false
    t.index ["test_group", "attachment_id", "rule_id"], name: "index_alerts_on_test_group_and_attachment_id_and_rule_id"
  end

  create_table "attachments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
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
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "bug_id"
    t.integer "rule_id"
    t.integer "unused_reference_id"
    t.integer "task_id"
    t.index ["bug_id"], name: "index_attachments_on_bug_id"
    t.index ["bugzilla_attachment_id"], name: "index_attachments_on_bugzilla_attachment_id"
    t.index ["rule_id"], name: "index_attachments_on_rule_id"
    t.index ["task_id"], name: "index_attachments_on_task_id"
  end

  create_table "bug_reference_rule_links", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "reference_id"
    t.integer "link_id"
    t.string "link_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["link_type", "link_id"], name: "index_bug_reference_rule_links_on_link_type_and_link_id"
  end

  create_table "bugs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
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
    t.integer "unused_gid", default: 1
    t.integer "unused_sid"
    t.integer "unused_rev", default: 1
    t.datetime "assigned_at"
    t.datetime "pending_at"
    t.datetime "resolved_at"
    t.datetime "reopened_at"
    t.integer "work_time"
    t.integer "review_time"
    t.integer "rework_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.integer "unused_reference_id"
    t.integer "unused_rule_id"
    t.integer "unused_attachment_id"
    t.string "liberty", default: "CLEAR"
    t.string "whiteboard"
    t.index ["user_id"], name: "index_bugs_on_user_id"
  end

  create_table "bugs_rules", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "bug_id", default: 0, null: false
    t.integer "rule_id", default: 0, null: false
    t.text "unused_svn_result_output"
    t.integer "unused_svn_result_code"
    t.boolean "tested"
    t.index ["bug_id", "rule_id"], name: "index_bugs_rules_on_bug_id_and_rule_id", unique: true
  end

  create_table "bugs_tags", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "bug_id", null: false
    t.integer "tag_id", null: false
    t.index ["bug_id", "tag_id"], name: "index_bugs_tags_on_bug_id_and_tag_id", unique: true
    t.index ["bug_id"], name: "index_bugs_tags_on_bug_id"
    t.index ["tag_id"], name: "index_bugs_tags_on_tag_id"
  end

  create_table "cves", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "reference_id", null: false
    t.string "year", null: false
    t.string "cve_key", null: false
    t.text "description"
    t.string "severity"
    t.float "base_score", limit: 24
    t.float "impact_score", limit: 24
    t.float "exploit_score", limit: 24
    t.string "confidentiality_impact"
    t.string "integrity_impact"
    t.string "availability_impact"
    t.string "vector_string"
    t.string "access_vector"
    t.string "access_complexity"
    t.string "authentication"
    t.text "affected_systems", limit: 4294967295
    t.index ["cve_key"], name: "index_cves_on_cve_key", unique: true
    t.index ["reference_id"], name: "index_cves_on_reference_id", unique: true
  end

  create_table "delayed_jobs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "events", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "user"
    t.string "action"
    t.string "description"
    t.integer "progress"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "exploit_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "description"
    t.string "pcap_validation"
    t.integer "unused_exploit_id"
    t.index ["unused_exploit_id"], name: "index_exploit_types_on_unused_exploit_id"
  end

  create_table "exploits", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "data"
    t.integer "exploit_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "attachment_id"
    t.integer "unused_reference_id"
    t.index ["attachment_id"], name: "index_exploits_on_attachment_id"
    t.index ["exploit_type_id"], name: "index_exploits_on_exploit_type_id"
    t.index ["unused_reference_id"], name: "index_exploits_on_unused_reference_id"
  end

  create_table "exploits_references", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "exploit_id"
    t.integer "reference_id"
  end

  create_table "notes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text "comment"
    t.string "note_type"
    t.string "author"
    t.integer "notes_bugzilla_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "bug_id"
    t.index ["bug_id"], name: "index_notes_on_bug_id"
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
    t.string "reference_data"
    t.integer "reference_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["reference_type_id"], name: "index_references_on_reference_type_id"
  end

  create_table "roles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "role"
  end

  create_table "roles_users", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id", null: false
    t.integer "role_id", null: false
    t.index ["role_id"], name: "index_roles_users_on_role_id"
    t.index ["user_id", "role_id"], name: "index_roles_users_on_user_id_and_role_id", unique: true
  end

  create_table "rule_categories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "category"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rule_docs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "rule_id"
    t.text "summary"
    t.text "impact"
    t.text "details"
    t.text "affected_sys", limit: 4294967295
    t.text "attack_scenarios"
    t.text "ease_of_attack"
    t.text "false_positives"
    t.text "false_negatives"
    t.text "corrective_action"
    t.text "contributors"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "policies"
    t.boolean "is_community"
    t.index ["rule_id"], name: "index_rule_docs_on_rule_id"
  end

  create_table "rules", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
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
    t.integer "gid"
    t.integer "sid"
    t.integer "rev"
    t.string "state"
    t.boolean "unused_tested", default: false
    t.boolean "committed", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "task_id"
    t.integer "rule_category_id"
    t.string "filename"
    t.integer "linenumber"
    t.string "edit_status", null: false
    t.boolean "parsed", default: true, null: false
    t.boolean "on", default: true, null: false
    t.string "publish_status", null: false
    t.string "doc_status", default: "New", null: false
    t.text "svn_result_output"
    t.integer "svn_result_code"
    t.boolean "svn_success"
    t.index ["gid", "sid"], name: "index_rules_gid_and_sid", unique: true
    t.index ["rule_category_id"], name: "index_rules_on_rule_category_id"
    t.index ["task_id"], name: "index_rules_on_task_id"
  end

  create_table "saved_searches", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.text "session_query"
    t.text "session_search"
    t.string "name"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tags", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tasks", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.boolean "completed", default: false
    t.boolean "failed", default: false
    t.text "result", limit: 16777215
    t.string "task_type"
    t.integer "time_elapsed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "bug_id"
    t.integer "user_id"
    t.datetime "stats_updated_at"
    t.string "type", default: "Task"
    t.index ["bug_id"], name: "index_tasks_on_bug_id"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "test_reports", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "task_id", null: false
    t.integer "rule_id", null: false
    t.integer "bug_id"
    t.float "average_check", limit: 24
    t.float "average_match", limit: 24
    t.float "average_nonmatch", limit: 24
    t.index ["rule_id", "task_id"], name: "index_test_reports_on_rule_id_and_task_id", unique: true
  end

  create_table "unused_attachments_exploits", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "attachment_id"
    t.integer "exploit_id"
  end

  create_table "unused_attachments_rules", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "attachment_id"
    t.integer "rule_id"
  end

  create_table "unused_references_rules", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "reference_id"
    t.integer "rule_id"
    t.index ["reference_id"], name: "index_unused_references_rules_on_reference_id"
    t.index ["rule_id"], name: "index_unused_references_rules_on_rule_id"
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "cvs_username", null: false
    t.string "cec_username"
    t.string "kerberos_login"
    t.string "display_name"
    t.boolean "committer", default: false
    t.boolean "confirmed", default: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "class_level", default: 0, null: false
    t.string "authentication_token"
    t.integer "metrics_timeframe", default: 7
    t.integer "parent_id"
    t.integer "lft", null: false
    t.integer "rgt", null: false
    t.integer "depth", default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["cvs_username"], name: "index_users_on_cvs_username", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["lft"], name: "index_users_on_lft"
    t.index ["parent_id"], name: "index_users_on_parent_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["rgt"], name: "index_users_on_rgt"
  end

  create_table "versions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.string "item_type", limit: 191, null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", limit: 4294967295
    t.text "object_changes", limit: 4294967295
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

end
