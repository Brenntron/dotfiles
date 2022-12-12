ALTER TABLE `dispute_entries` ADD `auto_resolve_category` varchar(255);
INSERT INTO `schema_migrations` (`version`) VALUES ('20221017132004');