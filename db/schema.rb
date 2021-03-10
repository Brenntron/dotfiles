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


ActiveRecord::Schema.define(version: 2021_02_14_014754) do

  create_table "alerts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "test_group", null: false
    t.integer "rule_id", null: false
    t.integer "attachment_id", null: false
    t.string "policy"
    t.index ["test_group", "attachment_id", "rule_id"], name: "index_alerts_on_test_group_and_attachment_id_and_rule_id"
  end

  create_table "amp_naming_conventions", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "pattern"
    t.string "example"
    t.string "engine"
    t.text "engine_description"
    t.text "notes"
    t.text "public_notes"
    t.string "contact"
    t.integer "table_sequence"
    t.text "public_engine_description"
    t.index ["table_sequence"], name: "index_amp_naming_conventions_on_table_sequence", unique: true
  end

  create_table "attachments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
    t.integer "unused_rule_id"
    t.integer "task_id"
    t.string "rule_test_id"
    t.index ["bug_id"], name: "index_attachments_on_bug_id"
    t.index ["bugzilla_attachment_id"], name: "index_attachments_on_bugzilla_attachment_id"
    t.index ["task_id"], name: "index_attachments_on_task_id"
    t.index ["unused_rule_id"], name: "index_attachments_on_unused_rule_id"
  end

  create_table "bug_blockers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "snort_blocker_bug_id"
    t.integer "snort_blocked_bug_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["snort_blocked_bug_id"], name: "index_bug_blockers_on_snort_blocked_bug_id"
    t.index ["snort_blocker_bug_id", "snort_blocked_bug_id"], name: "index_bug_blockers"
  end

  create_table "bug_reference_rule_links", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "reference_id"
    t.integer "link_id"
    t.string "link_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["link_type", "link_id"], name: "index_bug_reference_rule_links_on_link_type_and_link_id"
    t.index ["reference_id", "link_type"], name: "index_reference_links_on_reference_and_link_type"
  end

  create_table "bugs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
    t.string "unused_opsys"
    t.string "unused_platform"
    t.string "priority"
    t.string "unused_severity"
    t.text "research_notes"
    t.text "committer_notes"
    t.integer "classification", default: 0
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
    t.string "liberty", default: "CLEAR"
    t.string "whiteboard"
    t.boolean "acknowledged", default: false
    t.boolean "snort_secure", default: false
    t.string "type", default: "Bug"
    t.datetime "due_date"
    t.index ["product"], name: "index_bugs_on_product"
    t.index ["state"], name: "index_bugs_on_state"
    t.index ["user_id"], name: "index_bugs_on_user_id"
  end

  create_table "bugs_rules", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "bug_id", default: 0, null: false
    t.integer "rule_id", default: 0, null: false
    t.boolean "tested"
    t.boolean "in_summary", default: false
    t.boolean "edited", default: false
    t.index ["bug_id", "rule_id"], name: "index_bugs_rules_on_bug_id_and_rule_id", unique: true
  end

  create_table "bugs_tags", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "bug_id", null: false
    t.integer "tag_id", null: false
    t.index ["bug_id", "tag_id"], name: "index_bugs_tags_on_bug_id_and_tag_id", unique: true
    t.index ["tag_id"], name: "index_bugs_tags_on_tag_id"
  end

  create_table "bugs_whiteboards", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.bigint "bug_id", null: false
    t.bigint "whiteboard_id", null: false
    t.index ["bug_id", "whiteboard_id"], name: "index_bugs_whiteboards_on_bug_id_and_whiteboard_id", unique: true
    t.index ["whiteboard_id"], name: "index_bugs_whiteboards_on_whiteboard_id"
  end

  create_table "companies", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_companies_on_name", unique: true
  end

  create_table "complaint_entries", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "complaint_id"
    t.string "subdomain"
    t.string "domain"
    t.text "path"
    t.float "wbrs_score"
    t.string "url_primary_category", limit: 2000
    t.string "resolution"
    t.text "resolution_comment"
    t.datetime "complaint_entry_resolved_at"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "viewable", default: true, null: false
    t.float "sbrs_score"
    t.text "uri"
    t.string "suggested_disposition"
    t.string "ip_address"
    t.string "entry_type"
    t.string "category", limit: 2000
    t.integer "user_id"
    t.boolean "is_important"
    t.datetime "case_resolved_at"
    t.datetime "case_assigned_at"
    t.text "internal_comment"
    t.boolean "was_dismissed", default: false
    t.text "uri_as_categorized"
    t.string "platform"
    t.integer "platform_id"
    t.index ["complaint_id"], name: "index_complaint_entries_on_complaint_id"
    t.index ["status", "created_at"], name: "index_complaint_entries_on_status_and_created_at"
    t.index ["status", "domain"], name: "index_complaint_entries_on_status_and_domain"
    t.index ["user_id", "status"], name: "index_complaint_entries_on_user_id_and_status"
  end

  create_table "complaint_entry_preloads", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "complaint_entry_id"
    t.text "current_category_information", limit: 4294967295
    t.text "historic_category_information", limit: 4294967295
  end

  create_table "complaint_entry_screenshots", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "complaint_entry_id"
    t.binary "screenshot", limit: 16777215
    t.text "error_message", limit: 16777215
    t.index ["complaint_entry_id"], name: "index_complaint_entry_screenshots_on_complaint_entry_id"
  end

  create_table "complaint_tags", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_complaint_tags_on_name", unique: true
  end

  create_table "complaint_tags_complaints", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "complaint_id", null: false
    t.bigint "complaint_tag_id", null: false
    t.index ["complaint_id", "complaint_tag_id"], name: "idx_comp_comp_tag"
    t.index ["complaint_tag_id", "complaint_id"], name: "idx_comp_tag_comp"
  end

  create_table "complaints", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "channel"
    t.string "status"
    t.text "description", collation: "utf8mb4_general_ci"
    t.string "added_through"
    t.datetime "complaint_assigned_at"
    t.datetime "complaint_closed_at"
    t.string "resolution"
    t.text "resolution_comment"
    t.string "region"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "customer_id"
    t.integer "ticket_source_key"
    t.string "ticket_source"
    t.string "ticket_source_type"
    t.string "submission_type"
    t.string "submitter_type"
    t.string "product_platform"
    t.string "product_version"
    t.boolean "in_network"
    t.integer "platform_id"

    t.index ["channel", "customer_id"], name: "index_complaints_on_channel_and_customer_id"
    t.index ["customer_id"], name: "index_complaints_on_customer_id"
    t.index ["status", "customer_id"], name: "index_complaints_on_status_and_customer_id"
  end

  create_table "customers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_id"
    t.string "name"
    t.string "email"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_customers_on_company_id_and_name"
    t.index ["email"], name: "index_customers_on_email", unique: true
  end

  create_table "cves", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "reference_id", null: false
    t.string "year", null: false
    t.string "cve_key", null: false
    t.text "description"
    t.string "severity"
    t.float "base_score"
    t.float "impact_score"
    t.float "exploit_score"
    t.string "confidentiality_impact"
    t.string "integrity_impact"
    t.string "availability_impact"
    t.string "vector_string"
    t.string "attack_vector"
    t.string "attack_complexity"
    t.string "authentication"
    t.text "affected_systems", limit: 4294967295
    t.string "snort_doc_status", default: "NOTYET", null: false
    t.text "scope"
    t.text "user_interaction"
    t.text "privileges_required"
    t.string "attack_complexity"
    t.string "attack_vector"
    t.index ["cve_key"], name: "index_cves_on_cve_key", unique: true
    t.index ["reference_id"], name: "index_cves_on_reference_id", unique: true
  end

  create_table "delayed_jobs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", limit: 16777215
    t.text "last_error", limit: 16777215
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "digital_signers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "file_reputation_dispute_id", null: false
    t.string "issuer"
    t.string "subject"
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.index ["file_reputation_dispute_id"], name: "index_digital_signers_on_file_reputation_dispute_id"
  end

  create_table "dispute_comments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "dispute_id"
    t.text "comment"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dispute_id"], name: "index_dispute_comments_on_dispute_id"
  end

  create_table "dispute_email_attachments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "dispute_email_id"
    t.integer "bugzilla_attachment_id"
    t.string "file_name"
    t.text "direct_upload_url"
    t.integer "size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dispute_email_id", "bugzilla_attachment_id"], name: "index_dispute_email_attachments_on_email_and_attachment"
  end

  create_table "dispute_emails", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "dispute_id"
    t.text "email_headers"
    t.string "from"
    t.text "to"
    t.text "subject"
    t.text "body"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "email_sent_at"
    t.bigint "file_reputation_dispute_id"
    t.index ["dispute_id"], name: "index_dispute_emails_on_dispute_id"
    t.index ["file_reputation_dispute_id"], name: "index_dispute_emails_on_file_reputation_dispute_id"
  end

  create_table "dispute_entries", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "dispute_id"
    t.string "ip_address"
    t.text "uri"
    t.string "hostname"
    t.string "entry_type"
    t.float "score"
    t.string "score_type"
    t.string "suggested_disposition"
    t.string "primary_category"
    t.string "tag"
    t.string "top_level_domain"
    t.string "subdomain"
    t.string "domain"
    t.text "path"
    t.string "channel"
    t.string "status"
    t.string "resolution"
    t.text "resolution_comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "sbrs_score"
    t.float "wbrs_score"
    t.integer "webrep_wlbl_key"
    t.integer "reptool_key"
    t.boolean "is_important"
    t.integer "user_id"
    t.datetime "case_opened_at"
    t.datetime "case_closed_at"
    t.datetime "case_accepted_at"
    t.datetime "case_resolved_at"
    t.text "web_ips"
    t.text "proxy_url"
    t.text "multi_wbrs_threat_category"
    t.text "wbrs_threat_category"
    t.text "auto_resolve_log"
    t.string "platform"
    t.integer "platform_id"

    t.index ["dispute_id"], name: "index_dispute_entries_on_dispute_id"
  end

  create_table "dispute_entry_preloads", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "dispute_entry_id"
    t.text "xbrs_history", limit: 4294967295
    t.text "crosslisted_urls", limit: 4294967295
    t.text "virustotal", limit: 4294967295
    t.text "wlbl", limit: 4294967295
    t.text "wbrs_list_type", limit: 4294967295
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "umbrella", limit: 4294967295
    t.string "wbrs_threat_category"
    t.text "multi_wbrs_threat_category"
    t.index ["dispute_entry_id"], name: "index_dispute_entry_preloads_on_dispute_entry_id"
  end

  create_table "dispute_peeks", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "dispute_id"
    t.index ["user_id", "dispute_id"], name: "index_dispute_peeks_on_user_id_and_dispute_id", unique: true
  end

  create_table "dispute_rule_hits", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "rule_number"
    t.string "mnemonic"
    t.string "name"
    t.string "rule_type"
    t.integer "dispute_entry_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_multi_ip_rulehit"
    t.index ["dispute_entry_id", "rule_number"], name: "index_dispute_rule_hits_on_dispute_entry_id_and_rule_number"
  end

  create_table "dispute_rules", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "mnemonic"
    t.text "description"
    t.string "rule_type"
    t.integer "rule_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_dispute_rules_on_name"
  end

  create_table "disputes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "case_number"
    t.string "case_guid"
    t.string "org_domain"
    t.datetime "case_opened_at"
    t.datetime "case_closed_at"
    t.datetime "case_accepted_at"
    t.datetime "case_resolved_at"
    t.string "status"
    t.string "resolution"
    t.string "priority"
    t.text "subject"
    t.text "description", collation: "utf8mb4_general_ci"
    t.string "source_ip_address"
    t.text "problem_summary"
    t.text "research_notes"
    t.string "channel"
    t.integer "ticket_source_key"
    t.string "ticket_source"
    t.string "ticket_source_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "customer_id"
    t.integer "user_id"
    t.string "submission_type"
    t.string "submitter_type"
    t.integer "related_id"
    t.datetime "case_responded_at"
    t.datetime "related_at"
    t.text "resolution_comment"
    t.text "status_comment"
    t.text "parse_body", limit: 16777215
    t.integer "ticket_email_id"
    t.string "product_platform"
    t.string "product_version"
    t.boolean "in_network"
    t.integer "platform_id"
    t.index ["customer_id"], name: "index_disputes_on_customer_id"
  end

  create_table "email_templates", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "template_name"
    t.text "description"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["template_name"], name: "index_email_templates_on_template_name"
  end

  create_table "escalation_links", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "snort_escalation_bug_id"
    t.integer "snort_research_bug_id"
    t.index ["snort_escalation_bug_id"], name: "index_escalation_links_on_snort_escalation_bug_id"
    t.index ["snort_research_bug_id", "snort_escalation_bug_id"], name: "index_escalation_links"
  end

  create_table "events", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "user"
    t.string "action"
    t.string "description"
    t.integer "progress"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user"], name: "index_events_on_user"
  end

  create_table "exploit_types", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "pcap_validation"
    t.index ["name"], name: "index_exploit_types_on_name"
  end

  create_table "exploits", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "data"
    t.integer "exploit_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "attachment_id"
    t.index ["attachment_id"], name: "index_exploits_on_attachment_id"
    t.index ["exploit_type_id"], name: "index_exploits_on_exploit_type_id"
  end

  create_table "exploits_references", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "exploit_id"
    t.integer "reference_id"
    t.index ["exploit_id", "reference_id"], name: "index_exploits_references_on_exploit_id_and_reference_id"
    t.index ["reference_id"], name: "index_exploits_references_on_reference_id"
  end

  create_table "false_positive_selections", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "display"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "false_positives", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "bug_id"
    t.string "user_email"
    t.string "sid"
    t.text "description"
    t.string "source_authority"
    t.string "source_key"
    t.string "os"
    t.string "version"
    t.string "built_from"
    t.string "pcap_lib"
    t.string "cmd_line_options"
    t.index ["source_authority", "source_key"], name: "index_false_positives_on_source_authority_and_source_key", unique: true
  end

  create_table "file_references", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.string "file_name"
    t.text "location"
    t.string "file_type_name"
    t.string "source"
  end

  create_table "file_rep_comments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "file_reputation_dispute_id", null: false
    t.bigint "user_id", null: false
    t.text "comment"
    t.index ["file_reputation_dispute_id", "user_id"], name: "index_file_rep_comments_on_file_reputation_dispute_id"
  end

  create_table "file_rep_email_templates", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "user_id"
    t.string "template_name"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
  end

  create_table "file_reputation_disputes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "customer_id"
    t.string "status", default: "NEW", null: false
    t.string "source"
    t.string "platform"
    t.text "description", collation: "utf8mb4_general_ci"
    t.string "file_name", collation: "utf8mb4_general_ci"
    t.integer "file_size"
    t.string "sha256_hash"
    t.string "sample_type"
    t.string "disposition"
    t.string "disposition_suggested"
    t.bigint "user_id"
    t.float "sandbox_score"
    t.float "sandbox_threshold"
    t.string "sandbox_signer"
    t.boolean "has_sample"
    t.boolean "in_zoo"
    t.float "threatgrid_score"
    t.float "threatgrid_threshold"
    t.string "threatgrid_signer"
    t.boolean "threatgrid_private"
    t.integer "reversing_labs_score"
    t.string "reversing_labs_signer"
    t.string "resolution"
    t.string "detection_name"
    t.datetime "detection_last_set"
    t.datetime "case_closed_at"
    t.datetime "case_responded_at"
    t.integer "reversing_labs_count"
    t.string "sandbox_key"
    t.text "resolution_comment"
    t.datetime "last_fetched"
    t.text "reversing_labs_raw", limit: 16777215
    t.integer "ticket_source_key"
    t.string "submitter_type"
    t.text "auto_resolve_log"
    t.text "parse_body", limit: 16777215
    t.integer "ticket_email_id"
    t.string "product_platform"
    t.string "product_version"
    t.boolean "in_network"
    t.integer "platform_id"
    t.index ["created_at"], name: "index_file_reputation_disputes_on_created_at"
    t.index ["customer_id"], name: "index_file_reputation_disputes_on_customer_id"
    t.index ["sha256_hash"], name: "index_file_reputation_disputes_on_sha256_hash"
    t.index ["updated_at"], name: "index_file_reputation_disputes_on_updated_at"
    t.index ["user_id"], name: "index_file_reputation_disputes_on_user_id"
  end

  create_table "form_prefills", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "field"
    t.text "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fp_file_refs", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "false_positive_id"
    t.integer "file_reference_id"
    t.index ["false_positive_id", "file_reference_id"], name: "index_fp_file_refs"
    t.index ["file_reference_id"], name: "index_fp_file_refs_on_file_reference_id"
  end

  create_table "giblets", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "bug_id"
    t.string "name"
    t.string "gib_type"
    t.bigint "gib_id"
    t.index ["bug_id", "gib_type", "gib_id"], name: "index_giblets_on_bug_id_and_gib_type_and_gib_id"
    t.index ["gib_type", "gib_id"], name: "index_giblets_on_gib_type_and_gib_id"
  end

  create_table "mitre_data", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "external_id", null: false
    t.string "platform", default: "enterprise"
    t.string "category", null: false
    t.string "sub_category", null: false
    t.datetime "modified"
    t.datetime "created"
    t.text "description", null: false
    t.text "detection", null: false
    t.text "url", null: false
    t.string "version", default: "1.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "mitre_tactic_id"
    t.index ["category"], name: "index_mitre_data_on_category", length: 191
    t.index ["external_id"], name: "index_mitre_data_on_external_id", length: 191
    t.index ["mitre_tactic_id"], name: "index_mitre_data_on_mitre_tactic_id"
    t.index ["sub_category"], name: "index_mitre_data_on_sub_category", length: 191
  end

  create_table "morsels", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.text "output"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "named_search_criteria", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "named_search_id"
    t.string "field_name"
    t.text "value"
    t.index ["named_search_id"], name: "index_named_search_criteria_on_named_search_id"
  end

  create_table "named_searches", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "name"
    t.string "project_type"
    t.index ["user_id", "name"], name: "index_named_searches_on_user_id_and_name", unique: true
  end

  create_table "notes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "comment"
    t.string "note_type"
    t.string "author"
    t.integer "notes_bugzilla_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "bug_id"
    t.index ["bug_id"], name: "index_notes_on_bug_id"
  end

  create_table "org_subsets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_org_subsets_on_name"
  end

  create_table "platforms", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "public_name"
    t.string "internal_name"
    t.boolean "webrep", null: false
    t.boolean "emailrep", null: false
    t.boolean "webcat", null: false
    t.boolean "filerep", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reference_types", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "validation"
    t.string "bugzilla_format"
    t.string "example"
    t.string "rule_format"
    t.string "url"
    t.index ["name"], name: "index_reference_types_on_name"
  end

  create_table "references", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "reference_data"
    t.integer "reference_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "fail_count"
    t.index ["reference_type_id"], name: "index_references_on_reference_type_id"
  end

  create_table "resolution_message_templates", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "role"
    t.integer "org_subset_id"
    t.index ["org_subset_id"], name: "index_roles_on_org_subset_id"
    t.index ["role"], name: "index_roles_on_role"
  end

  create_table "roles_users", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "role_id", null: false
    t.index ["role_id"], name: "index_roles_users_on_role_id"
    t.index ["user_id", "role_id"], name: "index_roles_users_on_user_id_and_role_id", unique: true
  end

  create_table "rule_associations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "snort2_rule_id"
    t.bigint "snort3_rule_id"
  end

  create_table "rule_categories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "blurb"
    t.index ["category"], name: "index_rule_categories_on_category"
  end

  create_table "rule_docs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
    t.string "snort_doc_status", default: "NOTYET"
    t.string "snort_on_off", default: "on"
    t.index ["rule_id"], name: "index_rule_docs_on_rule_id"
  end

  create_table "rule_documents", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "rule_id", null: false
    t.integer "rule_vulnerability_id"
    t.text "trigger"
    t.text "explanation", null: false
    t.text "refs"
    t.integer "false_positive_selection_id", null: false
    t.text "false_positive_blurb"
    t.text "contributors"
    t.boolean "seen_in_wild"
    t.string "snort_doc_status", default: "NOTYET", null: false
    t.string "mitre_category"
    t.string "mitre_sub_category"
    t.string "known_usage"
    t.integer "mitre_tactic_id"
    t.integer "mitre_technique_id"
    t.boolean "is_deleted"
    t.integer "rule_id_coverage"
    t.index ["rule_id"], name: "index_rule_documents_on_rule_id", unique: true
  end

  create_table "rule_vulnerabilities", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "display_name"
    t.text "blurb"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rulehit_resolution_mailer_templates", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "mnemonic"
    t.string "to"
    t.string "cc"
    t.string "subject"
    t.text "body", limit: 4294967295
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rules", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
    t.string "snort_doc_status", default: "NOTYET"
    t.string "snort_on_off", default: "on"
    t.string "fatal_errors"
    t.boolean "edited", default: false
    t.string "type", default: "Snort2Rule"
    t.text "pre_normalized_rule"
    t.integer "autoconvert", default: 0
    t.index ["rule_category_id"], name: "index_rules_on_rule_category_id"
    t.index ["task_id"], name: "index_rules_on_task_id"
    t.index ["type", "gid", "sid"], name: "index_rules_on_type_and_gid_and_sid", unique: true
  end

  create_table "saved_searches", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.text "session_query"
    t.text "session_search"
    t.string "name"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "product"
    t.index ["user_id", "name"], name: "index_saved_searches_on_user_id_and_name"
  end

  create_table "sessions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "snort_researches", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "bug_id"
    t.integer "snort_research_to_research_bug_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bug_id", "snort_research_to_research_bug_id"], name: "index_snort_researches"
    t.index ["snort_research_to_research_bug_id"], name: "index_snort_researches_researches"
  end

  create_table "tags", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_tags_on_name"
  end

  create_table "tasks", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
    t.string "policy"
    t.datetime "scheduled_at"
    t.datetime "completed_at"
    t.datetime "started_at"
    t.boolean "timed_out", default: false
    t.integer "engine_id"
    t.index ["bug_id"], name: "index_tasks_on_bug_id"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "test_queue_events", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "unstarted"
    t.integer "running"
    t.string "event"
    t.datetime "event_time"
    t.integer "engine_id"
    t.bigint "prior_event_id"
    t.bigint "task_id"
    t.string "task_type"
    t.index ["prior_event_id"], name: "index_test_queue_events_on_prior_event_id"
  end

  create_table "test_reports", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "task_id", null: false
    t.integer "rule_id", null: false
    t.integer "bug_id"
    t.float "average_check"
    t.float "average_match"
    t.float "average_nonmatch"
    t.index ["rule_id", "task_id"], name: "index_test_reports_on_rule_id_and_task_id", unique: true
  end

  create_table "tested_policies", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "rule_id"
    t.integer "bug_id"
    t.string "policy"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
  
  create_table "ticket_email_attachments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "ticket_email_id"
    t.integer "bugzilla_attachment_id"
    t.string "file_name"
    t.text "direct_upload_url"
    t.integer "size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ticket_emails", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "bugzilla_id"
    t.text "email_headers"
    t.text "from"
    t.text "to"
    t.text "subject"
    t.text "body", limit: 16777215
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "parse_report", limit: 16777215
    t.text "simulation_results", limit: 16777215
    t.boolean "is_simulation"
  end

  create_table "unused_complaint_marked_commits", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "complaint_entry_id"
    t.string "comment"
    t.string "category_list"
    t.index ["user_id"], name: "index_unused_complaint_marked_commits_on_user_id"
  end

  create_table "unused_escalations", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "snort_research_escalation_bug_id"
    t.integer "snort_escalation_research_bug_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_api_keys", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "api_key"
    t.index ["api_key"], name: "index_user_api_keys_on_api_key", unique: true
  end

  create_table "user_preferences", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.string "name"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_user_preferences_on_user_id"
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
    t.string "bugzilla_api_key"
    t.string "threatgrid_api_key"
    t.string "sandbox_api_key"
    t.index ["cvs_username"], name: "index_users_on_cvs_username", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["lft"], name: "index_users_on_lft"
    t.index ["parent_id"], name: "index_users_on_parent_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["rgt"], name: "index_users_on_rgt"
  end

  create_table "versions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "item_type", limit: 191, null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", limit: 4294967295
    t.text "object_changes", limit: 4294967295
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "wbnp_reports", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "total_new_cases"
    t.integer "cases_imported"
    t.integer "cases_failed"
    t.string "status"
    t.text "notes", limit: 16777215
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "whiteboards", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_whiteboards_on_name"
  end

end
