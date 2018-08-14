ALTER TABLE `complaint_entries` ADD `internal_comment` text;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180812154342');