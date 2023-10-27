class Schema2018mid < ActiveRecord::Migration[5.1]
  def change

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

    create_table "bug_blockers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer "snort_blocker_bug_id"
      t.integer "snort_blocked_bug_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["snort_blocked_bug_id"], name: "index_bug_blockers_on_snort_blocked_bug_id"
      t.index ["snort_blocker_bug_id", "snort_blocked_bug_id"], name: "index_bug_blockers"
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
      t.text "committer_notes"
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
      t.boolean "acknowledged", default: false
      t.boolean "snort_secure", default: false
      t.string "type", default: "Bug"
      t.index ["product"], name: "index_bugs_on_product"
      t.index ["state"], name: "index_bugs_on_state"
      t.index ["user_id"], name: "index_bugs_on_user_id"
    end

    create_table "bugs_rules", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer "bug_id", default: 0, null: false
      t.integer "rule_id", default: 0, null: false
      t.text "unused_svn_result_output"
      t.integer "unused_svn_result_code"
      t.boolean "tested"
      t.boolean "in_summary", default: false
      t.index ["bug_id", "rule_id"], name: "index_bugs_rules_on_bug_id_and_rule_id", unique: true
    end

    create_table "bugs_tags", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer "bug_id", null: false
      t.integer "tag_id", null: false
      t.index ["bug_id", "tag_id"], name: "index_bugs_tags_on_bug_id_and_tag_id", unique: true
      t.index ["tag_id"], name: "index_bugs_tags_on_tag_id"
    end

    create_table "bugs_whiteboards", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
      t.bigint "bug_id", null: false
      t.bigint "whiteboard_id", null: false
      t.index ["bug_id", "whiteboard_id"], name: "index_bugs_whiteboards_on_bug_id_and_whiteboard_id", unique: true
      t.index ["whiteboard_id"], name: "index_bugs_whiteboards_on_whiteboard_id"
    end

    create_table "companies", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "name"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["name"], name: "index_companies_on_name", unique: true
    end

    create_table "complaint_entries", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer "complaint_id"
      t.string "subdomain"
      t.string "domain"
      t.string "path"
      t.float "wbrs_score", limit: 24
      t.string "url_primary_category"
      t.string "resolution"
      t.text "resolution_comment"
      t.datetime "complaint_entry_resolved_at"
      t.string "status"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.boolean "viewable", default: true, null: false
      t.float "sbrs_score", limit: 24
      t.text "uri"
      t.string "suggested_disposition"
      t.string "ip_address"
      t.string "entry_type"
      t.string "category"
      t.integer "user_id"
      t.boolean "is_important"
      t.datetime "case_resolved_at"
      t.datetime "case_assigned_at"
      t.text "internal_comment"
      t.boolean "was_dismissed", default: false
      t.index ["complaint_id"], name: "index_complaint_entries_on_complaint_id"
    end

    create_table "complaint_entry_preloads", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.bigint "complaint_entry_id"
      t.text "current_category_information", limit: 4294967295
      t.text "historic_category_information", limit: 4294967295
    end

    create_table "complaint_entry_screenshots", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "complaint_entry_id"
      t.binary "screenshot", limit: 16777215
      t.string "error_message", default: ""
      t.index ["complaint_entry_id"], name: "index_complaint_entry_screenshots_on_complaint_entry_id"
    end

    create_table "complaint_marked_commits", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "user_id"
      t.integer "complaint_entry_id"
      t.string "comment"
      t.string "category_list"
      t.index ["user_id"], name: "index_complaint_marked_commits_on_user_id"
    end

    create_table "complaint_tags", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "name"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["name"], name: "index_complaint_tags_on_name", unique: true
    end

    create_table "complaint_tags_complaints", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "complaint_id", null: false
      t.bigint "complaint_tag_id", null: false
      t.index ["complaint_id", "complaint_tag_id"], name: "idx_comp_comp_tag"
      t.index ["complaint_tag_id", "complaint_id"], name: "idx_comp_tag_comp"
    end

    create_table "complaints", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "channel"
      t.string "status"
      t.text "description"
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
      t.index ["customer_id"], name: "index_complaints_on_customer_id"
    end

    create_table "customers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer "company_id"
      t.string "name"
      t.string "email"
      t.string "phone"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["company_id", "name"], name: "index_customers_on_company_id_and_name", unique: true
    end

    create_table "cves", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
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

    create_table "dispute_comments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer "dispute_id"
      t.text "comment"
      t.integer "user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["dispute_id"], name: "index_dispute_comments_on_dispute_id"
    end

    create_table "dispute_email_attachments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer "dispute_email_id"
      t.integer "bugzilla_attachment_id"
      t.string "file_name"
      t.text "direct_upload_url"
      t.integer "size"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["dispute_email_id", "bugzilla_attachment_id"], name: "index_dispute_email_attachments_on_email_and_attachment"
    end

    create_table "dispute_emails", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
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
      t.index ["dispute_id"], name: "index_dispute_emails_on_dispute_id"
    end

    create_table "dispute_entries", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer "dispute_id"
      t.string "ip_address"
      t.text "uri"
      t.string "hostname"
      t.string "entry_type"
      t.float "score", limit: 24
      t.string "score_type"
      t.string "suggested_disposition"
      t.string "primary_category"
      t.string "tag"
      t.string "top_level_domain"
      t.string "subdomain"
      t.string "domain"
      t.string "path"
      t.string "channel"
      t.string "status"
      t.string "resolution"
      t.text "resolution_comment"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.float "sbrs_score", limit: 24
      t.float "wbrs_score", limit: 24
      t.integer "webrep_wlbl_key"
      t.integer "reptool_key"
      t.boolean "is_important"
      t.integer "user_id"
      t.datetime "case_opened_at"
      t.datetime "case_closed_at"
      t.datetime "case_accepted_at"
      t.datetime "case_resolved_at"
      t.index ["dispute_id"], name: "index_dispute_entries_on_dispute_id"
    end

    create_table "dispute_entry_preloads", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "dispute_entry_id"
      t.text "xbrs_history", limit: 4294967295
      t.text "crosslisted_urls", limit: 4294967295
      t.text "virustotal", limit: 4294967295
      t.text "wlbl", limit: 4294967295
      t.text "wbrs_list_type", limit: 4294967295
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.text "umbrella", limit: 4294967295
      t.index ["dispute_entry_id"], name: "index_dispute_entry_preloads_on_dispute_entry_id"
    end

    create_table "dispute_peeks", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "user_id"
      t.integer "dispute_id"
      t.index ["user_id", "dispute_id"], name: "index_dispute_peeks_on_user_id_and_dispute_id", unique: true
    end

    create_table "dispute_rule_hits", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer "rule_number"
      t.string "mnemonic"
      t.string "name"
      t.string "rule_type"
      t.integer "dispute_entry_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["dispute_entry_id", "rule_number"], name: "index_dispute_rule_hits_on_dispute_entry_id_and_rule_number"
    end

    create_table "dispute_rules", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "name"
      t.string "mnemonic"
      t.text "description"
      t.string "rule_type"
      t.integer "rule_number"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["name"], name: "index_dispute_rules_on_name"
    end

    create_table "disputes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
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
      t.text "description"
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
      t.index ["customer_id"], name: "index_disputes_on_customer_id"
    end

    create_table "email_templates", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "template_name"
      t.text "description"
      t.text "body"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["template_name"], name: "index_email_templates_on_template_name"
    end

    create_table "escalation_links", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "snort_escalation_bug_id"
      t.integer "snort_research_bug_id"
      t.index ["snort_escalation_bug_id"], name: "index_escalation_links_on_snort_escalation_bug_id"
      t.index ["snort_research_bug_id", "snort_escalation_bug_id"], name: "index_escalation_links"
    end

    create_table "escalations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
      t.integer "snort_research_escalation_bug_id"
      t.integer "snort_escalation_research_bug_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "events", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "user"
      t.string "action"
      t.string "description"
      t.integer "progress"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index ["user"], name: "index_events_on_user"
    end

    create_table "exploit_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "name"
      t.string "description"
      t.string "pcap_validation"
      t.integer "unused_exploit_id"
      t.index ["name"], name: "index_exploit_types_on_name"
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
      t.index ["exploit_id", "reference_id"], name: "index_exploits_references_on_exploit_id_and_reference_id"
      t.index ["reference_id"], name: "index_exploits_references_on_reference_id"
    end

    create_table "false_positives", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "bug_id"
      t.string "user_email"
      t.string "sid"
      t.string "description"
      t.string "source_authority"
      t.string "source_key"
      t.string "os"
      t.string "version"
      t.string "built_from"
      t.string "pcap_lib"
      t.string "cmd_line_options"
      t.index ["source_authority", "source_key"], name: "index_false_positives_on_source_authority_and_source_key", unique: true
    end

    create_table "file_references", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "type"
      t.string "file_name"
      t.text "location"
      t.string "file_type_name"
      t.string "source"
    end

    create_table "fp_file_refs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "false_positive_id"
      t.integer "file_reference_id"
      t.index ["false_positive_id", "file_reference_id"], name: "index_fp_file_refs"
      t.index ["file_reference_id"], name: "index_fp_file_refs_on_file_reference_id"
    end

    create_table "giblets", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
      t.integer "bug_id"
      t.string "name"
      t.string "gib_type"
      t.bigint "gib_id"
      t.index ["bug_id", "gib_type", "gib_id"], name: "index_giblets_on_bug_id_and_gib_type_and_gib_id"
      t.index ["gib_type", "gib_id"], name: "index_giblets_on_gib_type_and_gib_id"
    end

    create_table "morsels", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
      t.text "output"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "named_search_criteria", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "named_search_id"
      t.string "field_name"
      t.string "value"
      t.index ["named_search_id"], name: "index_named_search_criteria_on_named_search_id"
    end

    create_table "named_searches", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "user_id"
      t.string "name"
      t.index ["user_id", "name"], name: "index_named_searches_on_user_id_and_name", unique: true
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

    create_table "org_subsets", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "name"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["name"], name: "index_org_subsets_on_name"
    end

    create_table "reference_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "name"
      t.string "description"
      t.string "validation"
      t.string "bugzilla_format"
      t.string "example"
      t.string "rule_format"
      t.string "url"
      t.index ["name"], name: "index_reference_types_on_name"
    end

    create_table "references", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.text "reference_data"
      t.integer "reference_type_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer "fail_count"
      t.index ["reference_type_id"], name: "index_references_on_reference_type_id"
    end

    create_table "roles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "role"
      t.integer "org_subset_id"
      t.index ["org_subset_id"], name: "index_roles_on_org_subset_id"
      t.index ["role"], name: "index_roles_on_role"
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
      t.index ["category"], name: "index_rule_categories_on_category"
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

    create_table "rulehit_resolution_mailer_templates", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "mnemonic"
      t.string "to"
      t.string "cc"
      t.string "subject"
      t.text "body", limit: 4294967295
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
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
      t.string "snort_doc_status", default: "NOTYET"
      t.string "snort_on_off", default: "on"
      t.string "fatal_errors"
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
      t.string "product"
      t.index ["user_id", "name"], name: "index_saved_searches_on_user_id_and_name"
    end

    create_table "snort_researches", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer "bug_id"
      t.integer "snort_research_to_research_bug_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["bug_id", "snort_research_to_research_bug_id"], name: "index_snort_researches"
      t.index ["snort_research_to_research_bug_id"], name: "index_snort_researches_researches"
    end

    create_table "tags", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "name", null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index ["name"], name: "index_tags_on_name"
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

    create_table "user_api_keys", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "user_id"
      t.string "api_key"
      t.index ["api_key"], name: "index_user_api_keys_on_api_key", unique: true
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

    create_table "whiteboards", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
      t.string "name", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["name"], name: "index_whiteboards_on_name"
    end

  end
end