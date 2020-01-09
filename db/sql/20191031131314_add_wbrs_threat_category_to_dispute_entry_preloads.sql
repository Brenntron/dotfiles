ALTER TABLE `dispute_entry_preloads` ADD `wbrs_threat_category` varchar(255);
INSERT INTO `schema_migrations` (`version`) VALUES ('20191031131314');