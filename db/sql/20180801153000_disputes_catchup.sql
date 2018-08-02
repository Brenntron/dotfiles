
CREATE TABLE `disputes` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `case_number` int, `case_guid` varchar(255), `customer_name` varchar(255), `customer_email` varchar(255), `customer_phone` varchar(255), `customer_company_name` varchar(255), `org_domain` varchar(255), `case_opened_at` datetime, `case_closed_at` datetime, `case_accepted_at` datetime, `case_resolved_at` datetime, `status` varchar(255), `resolution` varchar(255), `priority` varchar(255), `subject` text, `description` text, `assigned_to` int, `source_ip_address` varchar(255), `problem_summary` text, `research_notes` text, `channel` varchar(255), `ticket_source_key` int, `ticket_source` varchar(255), `ticket_source_type` varchar(255), `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180416162644');

CREATE TABLE `dispute_emails` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `dispute_id` int, `email_headers` text, `from` varchar(255), `to` text, `subject` text, `body` text, `status` varchar(255), `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180416164457');

CREATE TABLE `dispute_comments` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `dispute_id` int, `comment` text, `user_id` int, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180416164519');

CREATE TABLE `dispute_rule_hits` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `rule_number` int, `mnemonic` varchar(255), `name` varchar(255), `rule_type` varchar(255), `dispute_entry_id` int, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180416190008');

CREATE TABLE `dispute_entries` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `dispute_id` int, `ip_address` varchar(255), `uri` varchar(255), `hostname` varchar(255), `entry_type` varchar(255), `score` float, `score_type` varchar(255), `suggested_disposition` varchar(255), `primary_category` varchar(255), `tag` varchar(255), `top_level_domain` varchar(255), `subdomain` varchar(255), `domain` varchar(255), `path` varchar(255), `channel` varchar(255), `status` varchar(255), `resolution` varchar(255), `resolution_comment` text, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180417135314');

CREATE TABLE `email_templates` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `template_name` varchar(255), `description` text, `body` text, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180418135516');

CREATE TABLE `dispute_rules` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `name` varchar(255), `mnemonic` varchar(255), `description` text, `rule_type` varchar(255), `rule_number` int, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180418163111');

CREATE TABLE `named_searches` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL, `user_id` int, `name` varchar(255)) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180529200911');

CREATE TABLE `named_search_criteria` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL, `named_search_id` int, `field_name` varchar(255), `value` varchar(255)) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180529201142');

CREATE TABLE `dispute_email_attachments` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `dispute_email_id` int, `bugzilla_attachment_id` int, `file_name` varchar(255), `direct_upload_url` text, `size` int, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180531183731');

CREATE TABLE `complaints` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `tag` varchar(255), `channel` varchar(255), `status` varchar(255), `description` text, `added_through` varchar(255), `complaint_assigned_at` datetime, `complaint_closed_at` datetime, `resolution` varchar(255), `resolution_comment` text, `customer` varchar(255), `region` varchar(255), `user_id` int, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180612142300');

CREATE TABLE `complaint_entries` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `complaint_id` int, `tag` varchar(255), `subdomain` varchar(255), `domain` varchar(255), `path` varchar(255), `wbrs_score` int, `url_primary_category` varchar(255), `resolution` varchar(255), `resolution_comment` text, `complaint_entry_resolved_at` datetime, `status` varchar(255), `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180614145957');

CREATE TABLE `companies` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `name` varchar(255), `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180615173051');

CREATE TABLE `customers` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `company_id` int, `name` varchar(255), `email` varchar(255), `phone` varchar(255), `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL,  INDEX `index_customers_on_company_id`  (`company_id`)) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180615173156');

ALTER TABLE `complaints` ADD `customer_id` int;
CREATE  INDEX `index_complaints_on_customer_id`  ON `complaints` (`customer_id`);
ALTER TABLE `complaints` DROP `customer`;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180615173723');

ALTER TABLE `disputes` ADD `customer_id` int;
CREATE  INDEX `index_disputes_on_customer_id`  ON `disputes` (`customer_id`);
ALTER TABLE `disputes` DROP `customer_name`;
ALTER TABLE `disputes` DROP `customer_email`;
ALTER TABLE `disputes` DROP `customer_phone`;
ALTER TABLE `disputes` DROP `customer_company_name`;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180615173923');

ALTER TABLE `complaint_entries` ADD `viewable` tinyint(1) DEFAULT 1 NOT NULL;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180615204112');

ALTER TABLE `dispute_emails` ADD `email_sent_at` datetime;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180618170132');

ALTER TABLE `disputes` ADD `user_id` int;
ALTER TABLE `disputes` DROP `assigned_to`;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180619144613');

ALTER TABLE `complaints` ADD `ticket_source_key` int;
ALTER TABLE `complaints` ADD `ticket_source` varchar(255);
ALTER TABLE `complaints` ADD `ticket_source_type` varchar(255);
INSERT INTO `schema_migrations` (`version`) VALUES ('20180619150022');

ALTER TABLE `complaint_entries` ADD `sbrs_score` float;
ALTER TABLE `complaint_entries` CHANGE `wbrs_score` `wbrs_score` float DEFAULT NULL;
ALTER TABLE `complaint_entries` ADD `uri` text;
ALTER TABLE `complaint_entries` ADD `suggested_disposition` varchar(255);
ALTER TABLE `complaint_entries` ADD `ip_address` varchar(255);
ALTER TABLE `complaints` ADD `submission_type` varchar(255);
ALTER TABLE `complaints` ADD `submitter_type` varchar(255);
ALTER TABLE `complaint_entries` ADD `entry_type` varchar(255);
INSERT INTO `schema_migrations` (`version`) VALUES ('20180621224342');

ALTER TABLE `dispute_entries` CHANGE `uri` `uri` text DEFAULT NULL;
ALTER TABLE `disputes` ADD `submission_type` varchar(255);
ALTER TABLE `disputes` ADD `submitter_type` varchar(255);
ALTER TABLE `dispute_entries` ADD `sbrs_score` float;
ALTER TABLE `dispute_entries` ADD `wbrs_score` float;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180621231320');

ALTER TABLE `dispute_entries` ADD `webrep_wlbl_key` int;
ALTER TABLE `dispute_entries` ADD `reptool_key` int;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180627132219');

CREATE TABLE `complaint_marked_commits` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL, `user_id` int, `complaint_entry_id` int, `comment` varchar(255), `category_list` varchar(255)) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180629163701');

ALTER TABLE `complaint_entries` ADD `category` varchar(255);
INSERT INTO `schema_migrations` (`version`) VALUES ('20180703200116');

ALTER TABLE `dispute_entries` ADD `is_important` tinyint(1);
INSERT INTO `schema_migrations` (`version`) VALUES ('20180709125748');

ALTER TABLE `complaint_entries` ADD `user_id` int;
ALTER TABLE `complaints` DROP `user_id`;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180711030932');

CREATE TABLE `dispute_entry_preloads` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `dispute_entry_id` bigint, `xbrs_history` longtext, `crosslisted_urls` longtext, `virustotal` longtext, `wlbl` longtext, `wbrs_list_type` longtext, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL,  INDEX `index_dispute_entry_preloads_on_dispute_entry_id`  (`dispute_entry_id`)) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180711143730');

ALTER TABLE `complaint_entries` ADD `is_important` tinyint(1);
INSERT INTO `schema_migrations` (`version`) VALUES ('20180711201143');

ALTER TABLE `dispute_entries` ADD `user_id` int;
ALTER TABLE `dispute_entries` ADD `case_opened_at` datetime;
ALTER TABLE `dispute_entries` ADD `case_closed_at` datetime;
ALTER TABLE `dispute_entries` ADD `case_accepted_at` datetime;
ALTER TABLE `dispute_entries` ADD `case_resolved_at` datetime;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180711202236');

CREATE TABLE `rulehit_resolution_mailer_templates` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `mnemonic` varchar(255), `to` varchar(255), `cc` varchar(255), `subject` varchar(255), `body` varchar(255), `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180716101134');

ALTER TABLE `rulehit_resolution_mailer_templates` CHANGE `body` `body` longtext DEFAULT NULL;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180716101900');

CREATE TABLE `complaint_tags` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `name` varchar(255), `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180716175346');

ALTER TABLE `complaints` DROP `tag`;
ALTER TABLE `complaint_entries` DROP `tag`;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180716175512');

CREATE TABLE `complaint_tags_complaints` (`complaint_id` bigint NOT NULL, `complaint_tag_id` bigint NOT NULL,  INDEX `idx_comp_comp_tag`  (`complaint_id`, `complaint_tag_id`),  INDEX `idx_comp_tag_comp`  (`complaint_tag_id`, `complaint_id`)) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180716175830');

CREATE TABLE `dispute_peeks` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL, `user_id` int, `dispute_id` int) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
CREATE UNIQUE INDEX `index_dispute_peeks_on_user_id_and_dispute_id`  ON `dispute_peeks` (`user_id`, `dispute_id`);
INSERT INTO `schema_migrations` (`version`) VALUES ('20180719161218');

ALTER TABLE `dispute_entry_preloads` ADD `umbrella` longtext;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180720142558');

ALTER TABLE `disputes` ADD `related_id` int;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180726200023');

ALTER TABLE `disputes` ADD `case_responded_at` datetime;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180730165632');

ALTER TABLE `disputes` ADD `related_at` datetime;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180730184700');



-- marlpier extra
DROP INDEX index_bugs_tags_on_bug_id ON bugs_tags;
DROP INDEX index_bugs_whiteboards_on_bug_id ON bugs_whiteboards;
DROP INDEX index_exploit_types_on_unused_exploit_id ON exploit_types;

CREATE UNIQUE INDEX `index_companies_on_name` ON `companies` (`name`);
CREATE INDEX `index_complaint_entries_on_complaint_id` ON `complaint_entries` (`complaint_id`);
CREATE INDEX `index_complaint_marked_commits_on_user_id` ON `complaint_marked_commits` (`user_id`);
CREATE UNIQUE INDEX `index_complaint_tags_on_name` ON `complaint_tags` (`name`);
CREATE INDEX `index_dispute_comments_on_dispute_id` ON `dispute_comments` (`dispute_id`);
CREATE INDEX `index_dispute_email_attachments_on_email_and_attachment` ON `dispute_email_attachments` (`dispute_email_id`, `bugzilla_attachment_id`);
CREATE INDEX `index_dispute_emails_on_dispute_id` ON `dispute_emails` (`dispute_id`);
CREATE INDEX `index_dispute_entries_on_dispute_id` ON `dispute_entries` (`dispute_id`);
CREATE INDEX `index_dispute_rule_hits_on_dispute_entry_id_and_rule_number` ON `dispute_rule_hits` (`dispute_entry_id`, `rule_number`);
CREATE INDEX `index_dispute_rules_on_name` ON `dispute_rules` (`name`);
CREATE INDEX `index_email_templates_on_template_name` ON `email_templates` (`template_name`);
CREATE INDEX `index_events_on_user` ON `events` (`user`);
CREATE UNIQUE INDEX `index_named_searches_on_user_id_and_name` ON `named_searches` (`user_id`, `name`);
CREATE INDEX `index_named_search_criteria_on_named_search_id` ON `named_search_criteria` (`named_search_id`);
CREATE INDEX `index_org_subsets_on_name` ON `org_subsets` (`name`);
CREATE INDEX `index_roles_on_org_subset_id` ON `roles` (`org_subset_id`);

DROP INDEX index_customers_on_company_id ON customers;
CREATE UNIQUE INDEX `index_customers_on_company_id_and_name` ON `customers` (`company_id`, `name`);


