DROP INDEX `index_attachments_on_reference_id` ON `attachments`;
ALTER TABLE `attachments` CHANGE `reference_id` `unused_reference_id` int(11) DEFAULT NULL;
RENAME TABLE `attachments_exploits` TO `unused_attachments_exploits`;
RENAME TABLE `attachments_rules` TO `unused_attachments_rules`;
ALTER TABLE `bugs` CHANGE `gid` `unused_gid` int(11) DEFAULT 1;
ALTER TABLE `bugs` CHANGE `sid` `unused_sid` int(11) DEFAULT NULL;
ALTER TABLE `bugs` CHANGE `rev` `unused_rev` int(11) DEFAULT 1;
DROP INDEX `index_bugs_on_reference_id` ON `bugs`;
ALTER TABLE `bugs` CHANGE `reference_id` `unused_reference_id` int(11) DEFAULT NULL;
DROP INDEX `index_bugs_on_rule_id` ON `bugs`;
ALTER TABLE `bugs` CHANGE `rule_id` `unused_rule_id` int(11) DEFAULT NULL;
ALTER TABLE `bugs` CHANGE `attachment_id` `unused_attachment_id` int(11) DEFAULT NULL;
ALTER TABLE `bugs_rules` CHANGE `svn_result_output` `unused_svn_result_output` text DEFAULT NULL;
ALTER TABLE `bugs_rules` CHANGE `svn_result_code` `unused_svn_result_code` int(11) DEFAULT NULL;
ALTER TABLE `exploit_types` CHANGE `exploit_id` `unused_exploit_id` int(11) DEFAULT NULL;
ALTER TABLE `exploit_types` RENAME INDEX `index_exploit_types_on_exploit_id` TO `index_exploit_types_on_unused_exploit_id`;
ALTER TABLE `exploits` CHANGE `reference_id` `unused_reference_id` int(11) DEFAULT NULL;
ALTER TABLE `exploits` RENAME INDEX `index_exploits_on_reference_id` TO `index_exploits_on_unused_reference_id`;
RENAME TABLE `references_rules` TO `unused_references_rules`;
ALTER TABLE `unused_references_rules` RENAME INDEX `index_references_rules_on_reference_id` TO `index_unused_references_rules_on_reference_id`;
ALTER TABLE `unused_references_rules` RENAME INDEX `index_references_rules_on_rule_id` TO `index_unused_references_rules_on_rule_id`;
DROP INDEX `index_roles_users_on_user_id` ON `roles_users`;
ALTER TABLE `rules` CHANGE `tested` `unused_tested` tinyint(1) DEFAULT '0';
INSERT INTO `schema_migrations` (`version`) VALUES ('20170914205316');
