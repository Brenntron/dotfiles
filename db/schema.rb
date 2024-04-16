# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022093018080800) do

  create_table "alerts", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "test_group", null: false
    t.integer "rule_id", null: false
    t.integer "attachment_id", null: false
    t.string "policy"
    t.index ["test_group", "attachment_id", "rule_id"], name: "index_alerts_on_test_group_and_attachment_id_and_rule_id"
  end

  create_table "amp_naming_conventions", charset: "latin1", force: :cascade do |t|
    t.string "pattern"
    t.string "example"
    t.string "engine"
    t.text "engine_description"
    t.text "notes"
    t.text "public_notes"
    t.string "contact"
    t.text "private_engine_description"
  end

  create_table "attachment_links", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "ticket_id"
    t.string "ticket_type"
    t.bigint "attachment_id"
    t.string "kind", default: "File"
    t.string "attachment_type"
    t.index ["attachment_id"], name: "index_attachment_links_on_attachment_id"
    t.index ["ticket_type", "ticket_id"], name: "index_attachment_links_on_ticket_type_and_ticket_id"
  end

  create_table "attachments", charset: "utf8mb3", force: :cascade do |t|
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
    t.bigint "rule_test_api_id"
    t.string "direct_file_path"
    t.boolean "pcap_flag", default: false, null: false
    t.bigint "jira_attachment_id"
    t.string "stored_file_name"
    t.string "stored_file_key"
    t.string "content_type_group", default: "application/octet-stream"
    t.string "sequestration", default: "unrecognized"
    t.bigint "ticket_id"
    t.string "ticket_type"
    t.string "file_source_category", default: "research"
    t.string "file_source_record_type"
    t.bigint "file_source_record_id"
    t.string "rule_test_api_hash", collation: "ascii_general_ci"
    t.index ["bug_id"], name: "index_attachments_on_bug_id"
    t.index ["bugzilla_attachment_id"], name: "index_attachments_on_bugzilla_attachment_id"
    t.index ["task_id"], name: "index_attachments_on_task_id"
    t.index ["unused_rule_id"], name: "index_attachments_on_unused_rule_id"
  end

  create_table "bug_blockers", charset: "utf8mb3", force: :cascade do |t|
    t.integer "snort_blocker_bug_id"
    t.integer "snort_blocked_bug_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["snort_blocked_bug_id"], name: "index_bug_blockers_on_snort_blocked_bug_id"
    t.index ["snort_blocker_bug_id", "snort_blocked_bug_id"], name: "index_bug_blockers"
  end

  create_table "bug_jira_labels", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "bug_id"
    t.integer "jira_label_id"
    t.index ["bug_id", "jira_label_id"], name: "index_bug_jira_labels_on_bug_id", unique: true
    t.index ["jira_label_id"], name: "index_bug_jira_labels_on_jira_label_id"
  end

  create_table "bug_reference_rule_links", charset: "latin1", force: :cascade do |t|
    t.integer "reference_id"
    t.integer "link_id"
    t.string "link_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["link_type", "link_id"], name: "index_bug_reference_rule_links_on_link_type_and_link_id"
    t.index ["reference_id", "link_type"], name: "index_reference_links_on_reference_and_link_type"
  end

  create_table "bugs", charset: "utf8mb3", force: :cascade do |t|
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
    t.datetime "release_date"
    t.bigint "jira_id"
    t.string "jira_project_key"
    t.index ["product"], name: "index_bugs_on_product"
    t.index ["state"], name: "index_bugs_on_state"
    t.index ["user_id"], name: "index_bugs_on_user_id"
  end

  create_table "bugs_rules", charset: "utf8mb3", force: :cascade do |t|
    t.integer "bug_id", default: 0, null: false
    t.integer "rule_id", default: 0, null: false
    t.boolean "tested"
    t.boolean "in_summary", default: false
    t.boolean "edited", default: false
    t.index ["bug_id", "rule_id"], name: "index_bugs_rules_on_bug_id_and_rule_id", unique: true
  end

  create_table "bugs_tags", id: false, charset: "utf8mb3", force: :cascade do |t|
    t.integer "bug_id", null: false
    t.integer "tag_id", null: false
    t.index ["bug_id", "tag_id"], name: "index_bugs_tags_on_bug_id_and_tag_id", unique: true
    t.index ["tag_id"], name: "index_bugs_tags_on_tag_id"
  end

  create_table "bugs_whiteboards", id: false, charset: "latin1", force: :cascade do |t|
    t.bigint "bug_id", null: false
    t.bigint "whiteboard_id", null: false
    t.index ["bug_id", "whiteboard_id"], name: "index_bugs_whiteboards_on_bug_id_and_whiteboard_id", unique: true
    t.index ["whiteboard_id"], name: "index_bugs_whiteboards_on_whiteboard_id"
  end

  create_table "cluster_assignments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "permanent", default: false, null: false
    t.string "domain"
    t.integer "cluster_id"
    t.index ["user_id"], name: "index_cluster_assignments_on_user_id"
  end

  create_table "cluster_categorizations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "cluster_id"
    t.string "comment"
    t.string "category_ids"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_cluster_categorizations_on_user_id"
  end

  create_table "companies", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_companies_on_name", unique: true
  end

  create_table "complaint_entries", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "complaint_id"
    t.string "subdomain"
    t.string "domain"
    t.text "path", size: :medium
    t.float "wbrs_score"
    t.string "url_primary_category", limit: 2000
    t.string "resolution"
    t.text "resolution_comment", size: :medium
    t.datetime "complaint_entry_resolved_at"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "viewable", default: true, null: false
    t.float "sbrs_score"
    t.text "uri", size: :medium
    t.string "suggested_disposition"
    t.string "ip_address"
    t.string "entry_type"
    t.string "category", limit: 2000
    t.integer "user_id"
    t.boolean "is_important"
    t.datetime "case_resolved_at"
    t.datetime "case_assigned_at"
    t.text "internal_comment", size: :medium
    t.boolean "was_dismissed", default: false
    t.text "uri_as_categorized", size: :medium
    t.string "platform"
    t.integer "platform_id"
    t.integer "reviewer_id"
    t.integer "second_reviewer_id"
    t.index ["complaint_id"], name: "index_complaint_entries_on_complaint_id"
    t.index ["status", "created_at"], name: "index_complaint_entries_on_status_and_created_at"
    t.index ["status", "domain"], name: "index_complaint_entries_on_status_and_domain"
    t.index ["user_id", "status"], name: "index_complaint_entries_on_user_id_and_status"
  end

  create_table "complaint_entry_preloads", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "complaint_entry_id"
    t.text "current_category_information", size: :long
    t.text "historic_category_information", size: :long
    t.index ["complaint_entry_id", "id"], name: "index_complaint_entry_preloads_on_complaint_entry_id_and_id"
  end

  create_table "complaint_entry_screenshots", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "complaint_entry_id"
    t.binary "screenshot", size: :medium
    t.text "error_message", size: :medium
    t.index ["complaint_entry_id"], name: "index_complaint_entry_screenshots_on_complaint_entry_id"
  end

  create_table "complaint_tags", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_complaint_tags_on_name", unique: true
  end

  create_table "complaint_tags_complaints", id: false, charset: "utf8mb3", force: :cascade do |t|
    t.bigint "complaint_id", null: false
    t.bigint "complaint_tag_id", null: false
    t.index ["complaint_id", "complaint_tag_id"], name: "idx_comp_comp_tag"
    t.index ["complaint_tag_id", "complaint_id"], name: "idx_comp_tag_comp"
  end

  create_table "complaints", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "channel"
    t.string "status"
    t.text "description"
    t.string "added_through"
    t.datetime "complaint_assigned_at"
    t.datetime "complaint_closed_at"
    t.string "resolution"
    t.text "resolution_comment", size: :medium
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
    t.text "bridge_packet", size: :long
    t.text "import_log", size: :long
    t.text "meta_data", size: :medium
    t.index ["channel", "customer_id"], name: "index_complaints_on_channel_and_customer_id"
    t.index ["customer_id"], name: "index_complaints_on_customer_id"
    t.index ["status", "customer_id"], name: "index_complaints_on_status_and_customer_id"
  end

  create_table "customers", charset: "utf8mb3", force: :cascade do |t|
    t.integer "company_id"
    t.string "name"
    t.string "email"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_customers_on_company_id_and_name"
    t.index ["email"], name: "index_customers_on_email", unique: true
    t.index ["name"], name: "index_customers_on_name"
  end

  create_table "cves", charset: "latin1", force: :cascade do |t|
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
    t.string "access_vector"
    t.string "access_complexity"
    t.string "authentication"
    t.text "affected_systems", size: :long
    t.string "snort_doc_status", default: "NOTYET", null: false
    t.text "scope"
    t.text "user_interaction"
    t.text "privileges_required"
    t.string "attack_complexity"
    t.string "attack_vector"
    t.index ["cve_key"], name: "index_cves_on_cve_key"
    t.index ["reference_id"], name: "index_cves_on_reference_id", unique: true
  end

  create_table "delayed_jobs", charset: "utf8mb3", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", size: :medium
    t.text "last_error", size: :medium
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "digital_signers", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "file_reputation_dispute_id", null: false
    t.string "issuer"
    t.string "subject"
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.index ["file_reputation_dispute_id"], name: "index_digital_signers_on_file_reputation_dispute_id"
  end

  create_table "dispute_comments", charset: "utf8mb3", force: :cascade do |t|
    t.integer "dispute_id"
    t.text "comment"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dispute_id"], name: "index_dispute_comments_on_dispute_id"
  end

  create_table "dispute_email_attachments", charset: "utf8mb3", force: :cascade do |t|
    t.integer "dispute_email_id"
    t.integer "bugzilla_attachment_id"
    t.string "file_name"
    t.text "direct_upload_url"
    t.integer "size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dispute_email_id", "bugzilla_attachment_id"], name: "index_dispute_email_attachments_on_email_and_attachment"
  end

  create_table "dispute_emails", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "dispute_id"
    t.text "email_headers", size: :medium
    t.string "from"
    t.text "to", size: :medium
    t.text "subject", size: :medium
    t.text "body", size: :medium
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "email_sent_at"
    t.bigint "file_reputation_dispute_id"
    t.integer "sender_domain_reputation_dispute_id"
    t.index ["dispute_id"], name: "index_dispute_emails_on_dispute_id"
    t.index ["file_reputation_dispute_id"], name: "index_dispute_emails_on_file_reputation_dispute_id"
  end

  create_table "dispute_entries", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "dispute_id"
    t.string "ip_address"
    t.text "uri", size: :medium
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
    t.text "path", size: :medium
    t.string "channel"
    t.string "status"
    t.string "resolution"
    t.text "resolution_comment", size: :medium
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
    t.text "proxy_url", size: :medium
    t.text "multi_wbrs_threat_category", size: :medium
    t.text "wbrs_threat_category", size: :medium
    t.text "web_ips", size: :medium
    t.text "auto_resolve_log", size: :medium
    t.string "platform"
    t.integer "platform_id"
    t.text "suggested_threat_category", size: :medium
    t.string "auto_resolve_category"
    t.index ["dispute_id"], name: "index_dispute_entries_on_dispute_id"
  end

  create_table "dispute_entry_preloads", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "dispute_entry_id"
    t.text "xbrs_history", size: :long
    t.text "crosslisted_urls", size: :long
    t.text "virustotal", size: :long
    t.text "wlbl", size: :long
    t.text "wbrs_list_type", size: :long
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "umbrella", size: :long
    t.string "wbrs_threat_category"
    t.text "multi_wbrs_threat_category"
    t.index ["dispute_entry_id"], name: "index_dispute_entry_preloads_on_dispute_entry_id"
  end

  create_table "dispute_peeks", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "dispute_id"
    t.index ["user_id", "dispute_id"], name: "index_dispute_peeks_on_user_id_and_dispute_id", unique: true
  end

  create_table "dispute_rule_hits", charset: "utf8mb3", force: :cascade do |t|
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

  create_table "dispute_rules", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "mnemonic"
    t.text "description"
    t.string "rule_type"
    t.integer "rule_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_dispute_rules_on_name"
  end

  create_table "disputes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
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
    t.text "subject", size: :medium
    t.text "description"
    t.string "source_ip_address"
    t.text "problem_summary", size: :medium
    t.text "research_notes", size: :medium
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
    t.text "resolution_comment", size: :medium
    t.text "status_comment", size: :medium
    t.string "product_platform"
    t.string "product_version"
    t.boolean "in_network"
    t.integer "platform_id"
    t.text "bridge_packet", size: :long
    t.text "import_log", size: :long
    t.text "meta_data", size: :medium
    t.index ["customer_id"], name: "index_disputes_on_customer_id"
    t.index ["related_id"], name: "index_disputes_on_related_id"
    t.index ["user_id"], name: "index_disputes_on_user_id"
  end

  create_table "email_templates", charset: "utf8mb3", force: :cascade do |t|
    t.string "template_name"
    t.text "description"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["template_name"], name: "index_email_templates_on_template_name"
  end

  create_table "escalation_links", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "snort_escalation_bug_id"
    t.integer "snort_research_bug_id"
    t.index ["snort_escalation_bug_id"], name: "index_escalation_links_on_snort_escalation_bug_id"
    t.index ["snort_research_bug_id", "snort_escalation_bug_id"], name: "index_escalation_links"
  end

  create_table "escalation_tickets", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.text "ticket_data", size: :medium
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "events", charset: "utf8mb3", force: :cascade do |t|
    t.string "user"
    t.string "action"
    t.string "description"
    t.integer "progress"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user"], name: "index_events_on_user"
  end

  create_table "exploit_types", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "pcap_validation"
    t.index ["name"], name: "index_exploit_types_on_name"
  end

  create_table "exploits", charset: "utf8mb3", force: :cascade do |t|
    t.string "data"
    t.integer "exploit_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "attachment_id"
    t.index ["attachment_id"], name: "index_exploits_on_attachment_id"
    t.index ["exploit_type_id"], name: "index_exploits_on_exploit_type_id"
  end

  create_table "exploits_references", charset: "utf8mb3", force: :cascade do |t|
    t.integer "exploit_id"
    t.integer "reference_id"
    t.index ["exploit_id", "reference_id"], name: "index_exploits_references_on_exploit_id_and_reference_id"
    t.index ["reference_id"], name: "index_exploits_references_on_reference_id"
  end

  create_table "false_positive_selections", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "display"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "false_positives", charset: "latin1", force: :cascade do |t|
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

  create_table "file_references", charset: "latin1", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.string "file_name"
    t.text "location"
    t.string "file_type_name"
    t.string "source"
  end

  create_table "file_rep_comments", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "file_reputation_dispute_id", null: false
    t.bigint "user_id", null: false
    t.text "comment"
    t.index ["file_reputation_dispute_id", "user_id"], name: "index_file_rep_comments_on_file_reputation_dispute_id"
  end

  create_table "file_rep_email_templates", charset: "latin1", force: :cascade do |t|
    t.integer "user_id"
    t.string "template_name"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
  end

  create_table "file_reputation_disputes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "customer_id"
    t.string "status", default: "NEW", null: false
    t.string "source"
    t.string "platform"
    t.text "description"
    t.string "file_name"
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
    t.text "resolution_comment", size: :medium
    t.datetime "last_fetched"
    t.text "reversing_labs_raw", size: :long
    t.integer "ticket_source_key"
    t.string "submitter_type"
    t.text "auto_resolve_log", size: :medium
    t.string "product_platform"
    t.string "product_version"
    t.boolean "in_network"
    t.integer "platform_id"
    t.text "bridge_packet", size: :long
    t.text "import_log", size: :long
    t.text "meta_data", size: :medium
    t.index ["created_at"], name: "index_file_reputation_disputes_on_created_at"
    t.index ["customer_id"], name: "index_file_reputation_disputes_on_customer_id"
    t.index ["sha256_hash"], name: "index_file_reputation_disputes_on_sha256_hash"
    t.index ["updated_at"], name: "index_file_reputation_disputes_on_updated_at"
    t.index ["user_id"], name: "index_file_reputation_disputes_on_user_id"
  end

  create_table "form_prefills", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "field"
    t.text "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fp_file_refs", charset: "latin1", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "false_positive_id"
    t.integer "file_reference_id"
    t.index ["false_positive_id", "file_reference_id"], name: "index_fp_file_refs"
    t.index ["file_reference_id"], name: "index_fp_file_refs_on_file_reference_id"
  end

  create_table "giblets", charset: "latin1", force: :cascade do |t|
    t.integer "bug_id"
    t.string "name"
    t.string "gib_type"
    t.bigint "gib_id"
    t.index ["bug_id", "gib_type", "gib_id"], name: "index_giblets_on_bug_id_and_gib_type_and_gib_id"
    t.index ["gib_type", "gib_id"], name: "index_giblets_on_gib_type_and_gib_id"
  end

  create_table "import_urls", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "jira_import_task_id"
    t.text "submitted_url"
    t.string "domain"
    t.string "bast_verdict"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "complaint_id"
    t.string "verdict_reason"
  end

  create_table "jira_import_jobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "jira_issue_key"
    t.integer "status", default: 0
    t.integer "bast_status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "jira_import_tasks", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "issue_key", null: false
    t.string "status"
    t.string "result"
    t.string "submitter"
    t.integer "bast_task"
    t.datetime "imported_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "issue_summary"
    t.text "issue_description"
    t.string "issue_platform"
    t.string "issue_status"
    t.string "issue_type"
  end

  create_table "jira_issue_domains", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "domain"
    t.integer "domain_type"
    t.bigint "jira_import_job_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["jira_import_job_id"], name: "index_jira_issue_domains_on_jira_import_job_id"
  end

  create_table "jira_labels", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", limit: 256
    t.index ["name"], name: "index_jira_labels_on_name", unique: true
  end

  create_table "meraki_clusters", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "domain"
    t.bigint "platform_id"
    t.string "category_ids"
    t.integer "status", default: 0
    t.bigint "traffic_hits", default: 0
    t.string "comment"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["platform_id"], name: "index_meraki_clusters_on_platform_id"
  end

  create_table "mitre_data", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
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
    t.boolean "deprecated"
    t.index ["category"], name: "index_mitre_data_on_category", length: 191
    t.index ["external_id"], name: "index_mitre_data_on_external_id", length: 191
    t.index ["mitre_tactic_id"], name: "index_mitre_data_on_mitre_tactic_id"
    t.index ["sub_category"], name: "index_mitre_data_on_sub_category", length: 191
  end

  create_table "morsels", charset: "latin1", force: :cascade do |t|
    t.text "output"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "named_search_criteria", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "named_search_id"
    t.string "field_name"
    t.text "value"
    t.index ["named_search_id"], name: "index_named_search_criteria_on_named_search_id"
  end

  create_table "named_searches", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "name"
    t.string "project_type"
    t.index ["user_id", "name"], name: "index_named_searches_on_user_id_and_name", unique: true
  end

  create_table "ngfw_clusters", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.text "domain"
    t.bigint "traffic_hits"
    t.integer "platform_id"
    t.string "category_ids"
    t.integer "status", default: 0
    t.string "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["platform_id"], name: "index_ngfw_clusters_on_platform_id"
  end

  create_table "notes", charset: "utf8mb3", force: :cascade do |t|
    t.text "comment", size: :medium
    t.string "note_type"
    t.string "author"
    t.integer "notes_bugzilla_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "bug_id"
    t.bigint "jira_id"
    t.index ["bug_id"], name: "index_notes_on_bug_id"
  end

  create_table "oauth_access_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "pending", collation: "ascii_general_ci"
    t.string "resource_owner", default: "jira", collation: "ascii_general_ci"
    t.string "resource_site", default: "jira.vrt.sourcefire.com", collation: "ascii_general_ci"
    t.string "resource_name", limit: 20, default: "RESBZ", collation: "ascii_general_ci"
    t.string "location_uri", collation: "ascii_general_ci"
    t.bigint "user_id"
    t.string "redirect_uri", default: "/oauth/oauth_authentications/auth_request_result", collation: "ascii_general_ci"
    t.binary "state", limit: 36
    t.binary "code_verifier", limit: 36
    t.datetime "token_expires_at"
  end

  create_table "org_subsets", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_org_subsets_on_name"
  end

  create_table "platforms", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "public_name"
    t.string "internal_name"
    t.boolean "webrep", null: false
    t.boolean "emailrep", null: false
    t.boolean "webcat", null: false
    t.boolean "filerep", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "senderdomain"
  end

  create_table "reference_types", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "validation"
    t.string "bugzilla_format"
    t.string "example"
    t.string "rule_format"
    t.string "url"
    t.index ["name"], name: "index_reference_types_on_name"
  end

  create_table "references", charset: "utf8mb3", force: :cascade do |t|
    t.text "reference_data"
    t.integer "reference_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "fail_count"
    t.index ["reference_type_id"], name: "index_references_on_reference_type_id"
  end

  create_table "resolution_message_templates", charset: "latin1", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0
    t.string "ticket_type"
    t.string "resolution_type"
    t.bigint "creator_id"
    t.integer "editor_id"
  end

  create_table "roles", charset: "utf8mb3", force: :cascade do |t|
    t.string "role"
    t.integer "org_subset_id"
    t.index ["org_subset_id"], name: "index_roles_on_org_subset_id"
    t.index ["role"], name: "index_roles_on_role"
  end

  create_table "roles_users", id: false, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "role_id", null: false
    t.index ["role_id"], name: "index_roles_users_on_role_id"
    t.index ["user_id", "role_id"], name: "index_roles_users_on_user_id_and_role_id", unique: true
  end

  create_table "rule_associations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "snort2_rule_id"
    t.bigint "snort3_rule_id"
    t.boolean "local", default: true, null: false
    t.boolean "remote", default: false, null: false
  end

  create_table "rule_categories", charset: "utf8mb3", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "blurb"
    t.index ["category"], name: "index_rule_categories_on_category"
  end

  create_table "rule_docs", charset: "utf8mb3", force: :cascade do |t|
    t.integer "rule_id"
    t.text "summary"
    t.text "impact"
    t.text "details"
    t.text "affected_sys", size: :long
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

  create_table "rule_documents", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
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

  create_table "rule_group_rules", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "snort3_rule_id"
    t.bigint "rule_group_id"
    t.boolean "local", default: true
    t.boolean "remote", default: true
  end

  create_table "rule_groups", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "active"
    t.integer "groupid"
    t.integer "grouppid"
    t.text "name"
    t.text "fqn"
    t.text "node_type"
    t.text "description"
    t.text "commit_status"
    t.text "logtime"
    t.string "mitre_id"
  end

  create_table "rule_replacements", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "deleted_rule_id", null: false
    t.bigint "replacement_rule_id", null: false
    t.boolean "local", default: true
    t.boolean "remote", default: false
    t.index ["deleted_rule_id", "replacement_rule_id"], name: "index_rule_replacements_on_rule_ids", unique: true
  end

  create_table "rule_vulnerabilities", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "display_name"
    t.text "blurb"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rulehit_resolution_mailer_templates", charset: "utf8mb3", force: :cascade do |t|
    t.string "mnemonic"
    t.string "to"
    t.string "cc"
    t.string "subject"
    t.text "body", size: :long
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rules", charset: "utf8mb3", force: :cascade do |t|
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
    t.boolean "been_deleted", default: false
    t.boolean "remote_been_deleted", default: false
    t.string "delete_message"
    t.integer "file_data_count"
    t.integer "http_client_body_count"
    t.index ["rule_category_id"], name: "index_rules_on_rule_category_id"
    t.index ["task_id"], name: "index_rules_on_task_id"
    t.index ["type", "gid", "sid"], name: "index_rules_on_type_and_gid_and_sid", unique: true
  end

  create_table "saved_searches", charset: "latin1", force: :cascade do |t|
    t.text "session_query"
    t.text "session_search"
    t.string "name"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "product"
    t.index ["user_id", "name"], name: "index_saved_searches_on_user_id_and_name"
  end

  create_table "sender_domain_reputation_dispute_attachments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "sender_domain_reputation_dispute_id"
    t.integer "bugzilla_attachment_id"
    t.string "file_name"
    t.text "direct_upload_url"
    t.integer "size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "email_header_data"
    t.text "beaker_info", size: :medium
  end

  create_table "sender_domain_reputation_dispute_comments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "sender_domain_reputation_dispute_id"
    t.integer "user_id"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sender_domain_reputation_disputes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "platform_id"
    t.string "platform_version"
    t.text "sender_domain_entry"
    t.integer "user_id"
    t.string "source"
    t.string "suggested_disposition"
    t.string "status"
    t.string "resolution"
    t.text "resolution_comment"
    t.integer "customer_id"
    t.integer "ticket_source_key"
    t.string "submitter_type"
    t.text "bridge_packet", size: :medium
    t.text "meta_data", size: :medium
    t.text "description"
    t.datetime "case_assigned_at"
    t.datetime "case_closed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "priority"
    t.datetime "case_responded_at"
    t.text "beaker_info", size: :medium
  end

  create_table "sender_domain_reputation_email_templates", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "template_name"
    t.text "description"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", charset: "utf8mb3", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "snort_escalation_comments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "snort_escalation_id"
    t.integer "user_id"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "snort_escalation_cves", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "snort_escalation_id"
    t.bigint "cve_id"
  end

  create_table "snort_escalation_email_templates", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "template_name"
    t.text "description"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "snort_escalation_emails", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "snort_escalation_id"
    t.text "email_headers"
    t.string "from"
    t.string "to"
    t.string "cc"
    t.text "subject"
    t.text "body"
    t.string "status"
    t.datetime "email_sent_at"
    t.bigint "source_key"
  end

  create_table "snort_escalation_researches", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "bug_id"
    t.bigint "snort_escalation_id"
    t.boolean "escalated_bug_flag", default: false
  end

  create_table "snort_escalation_rule_topics", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "snort_escalation_id"
    t.bigint "rule_id"
  end

  create_table "snort_escalations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "summary"
    t.text "description"
    t.bigint "assignee_id"
    t.string "snort_version"
    t.string "ruleset"
    t.string "escalation_cause"
    t.string "platform"
    t.string "source"
    t.string "submitter_customer_tier"
    t.bigint "customer_id"
    t.string "priority"
    t.integer "source_key"
    t.string "ti_status"
    t.integer "researcher_id"
    t.string "lookup_item"
    t.string "status", default: "NEW", null: false, collation: "ascii_general_ci"
    t.text "status_comment"
    t.string "resolution"
    t.text "resolution_comment"
    t.text "auto_resolve_log", size: :medium
    t.string "auto_resolve_code"
    t.text "bridge_packet", size: :medium
    t.string "submitted_snort_rule"
    t.string "component", limit: 80, collation: "ascii_general_ci"
  end

  create_table "snort_escalations_tags", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "snort_escalation_id", null: false
    t.integer "tag_id", null: false
    t.index ["snort_escalation_id", "tag_id"], name: "index_snort_escalations_tags_on_snort_escalation_id_and_tag_id", unique: true
    t.index ["tag_id"], name: "index_snort_escalations_tags_on_tag_id"
  end

  create_table "tag_links", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tag_id"
    t.string "ticket_type"
    t.bigint "ticket_id"
    t.index ["tag_id"], name: "index_tag_links_on_tag_id"
    t.index ["ticket_type", "ticket_id", "tag_id"], name: "index_tag_links_on_ticket_type_and_ticket_id_and_tag_id", unique: true
  end

  create_table "tags", charset: "utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_tags_on_name"
  end

  create_table "tasks", charset: "utf8mb3", force: :cascade do |t|
    t.boolean "completed", default: false
    t.boolean "failed", default: false
    t.text "result", size: :medium
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
    t.string "test_run_id"
    t.string "build_version"
    t.string "lsp_version"
    t.string "policy_file_name"
    t.integer "lsp_snort_version_id"
    t.datetime "last_polled_at"
    t.index ["bug_id"], name: "index_tasks_on_bug_id"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "telemetry_histories", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.float "wbrs_score"
    t.float "sbrs_score"
    t.float "multi_ip_score"
    t.text "rule_hits"
    t.text "multi_rule_hits"
    t.text "threat_categories"
    t.text "multi_threat_categories"
    t.integer "dispute_entry_id"
    t.boolean "original_snapshot"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "test_queue_events", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
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

  create_table "test_reports", charset: "utf8mb3", force: :cascade do |t|
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

  create_table "tested_pcaps", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "task_id"
    t.bigint "pcap_id"
    t.bigint "rule_test_api_id"
  end

  create_table "tested_policies", charset: "utf8mb3", force: :cascade do |t|
    t.integer "rule_id"
    t.integer "bug_id"
    t.string "policy"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "umbrella_clusters", charset: "utf8mb3", force: :cascade do |t|
    t.string "domain", limit: 191
    t.integer "platform_id"
    t.string "category_ids"
    t.integer "status", default: 0
    t.bigint "traffic_hits", default: 0
    t.string "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["platform_id"], name: "index_umbrella_clusters_on_platform_id"
  end

  create_table "unused_complaint_marked_commits", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "complaint_entry_id"
    t.string "comment"
    t.string "category_list"
    t.index ["user_id"], name: "index_unused_complaint_marked_commits_on_user_id"
  end

  create_table "unused_escalations", charset: "latin1", force: :cascade do |t|
    t.integer "snort_research_escalation_bug_id"
    t.integer "snort_escalation_research_bug_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_api_keys", charset: "latin1", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "api_key"
    t.index ["api_key"], name: "index_user_api_keys_on_api_key", unique: true
  end

  create_table "user_preferences", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "user_id"
    t.string "name"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_user_preferences_on_user_id"
  end

  create_table "users", charset: "utf8mb3", force: :cascade do |t|
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
    t.index ["authentication_token"], name: "index_users_on_authentication_token"
    t.index ["cvs_username"], name: "index_users_on_cvs_username", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["lft"], name: "index_users_on_lft"
    t.index ["parent_id"], name: "index_users_on_parent_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["rgt"], name: "index_users_on_rgt"
  end

  create_table "versions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "item_type", limit: 191, null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", size: :long
    t.text "object_changes", size: :long
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "wbnp_reports", charset: "latin1", force: :cascade do |t|
    t.integer "total_new_cases"
    t.integer "cases_imported"
    t.integer "cases_failed"
    t.string "status"
    t.text "notes", size: :medium
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status_message"
    t.integer "attempts"
    t.integer "cases_skipped"
  end

  create_table "web_cat_clusters", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "domain"
    t.integer "platform_id"
    t.string "category_ids"
    t.integer "status"
    t.integer "traffic_hits"
    t.string "comment"
    t.string "cluster_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["cluster_type"], name: "index_web_cat_clusters_on_cluster_type"
  end

  create_table "webcat_credits", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "credit"
    t.integer "user_id"
    t.integer "complaint_entry_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.string "domain", limit: 191
    t.index ["complaint_entry_id"], name: "index_complaint_entry_credits_on_user_id"
    t.index ["user_id"], name: "index_complaint_entry_credits_on_complient_entry_id"
  end

  create_table "whiteboards", charset: "latin1", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_whiteboards_on_name"
  end

  add_foreign_key "jira_issue_domains", "jira_import_jobs"
end
