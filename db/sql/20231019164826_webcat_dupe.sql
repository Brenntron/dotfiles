ALTER TABLE `complaint_entries` ADD `canonical_id` int;
INSERT INTO `schema_migrations` (`version`) VALUES ('20231019164826');