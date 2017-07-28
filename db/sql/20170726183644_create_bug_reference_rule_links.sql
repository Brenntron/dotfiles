CREATE TABLE bug_reference_rule_links (id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, reference_id int, link_id int, link_type varchar(255), created_at datetime NOT NULL, updated_at datetime NOT NULL);
CREATE INDEX index_bug_reference_rule_links_on_link_id_and_link_type ON bug_reference_rule_links (link_id, link_type);
INSERT INTO schema_migrations (version) VALUES ('20170726183644');
INSERT INTO bug_reference_rule_links (reference_id, link_id, link_type, created_at, updated_at) SELECT reference_id, rule_id, 'Rule', now(), now() from references_rules;
