INSERT INTO `schema_migrations` (`version`) VALUES ('20180305175716');
ALTER TABLE `bug_rules` ADD `in_summary` BOOLEAN DEFAULT '0';