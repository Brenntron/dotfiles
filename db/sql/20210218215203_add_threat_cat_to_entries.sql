ALTER TABLE `dispute_entries` ADD `suggested_threat_category` text;
INSERT INTO `schema_migrations` (`version`) VALUES ('20210218215203');