ALTER TABLE `bugs_rules` ADD `svn_result_output` varchar(255);
ALTER TABLE `bugs_rules` ADD `svn_result_code` int;
CREATE UNIQUE INDEX `index_bugs_rules_on_bug_id_and_rule_id`  ON `bugs_rules` (`bug_id`, `rule_id`);
INSERT INTO `schema_migrations` (`version`) VALUES ('20170726135926');
