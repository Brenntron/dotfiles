DROP INDEX `index_bug_reference_rule_links_on_link_id_and_link_type` ON `bug_reference_rule_links`;
CREATE  INDEX `index_bug_reference_rule_links_on_link_type_and_link_id`  ON `bug_reference_rule_links` (`link_type`, `link_id`);
INSERT INTO `schema_migrations` (`version`) VALUES ('20171205164129');
