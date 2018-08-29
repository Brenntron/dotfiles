ALTER TABLE `complaint_entries` ADD `was_dismissed` tinyint(1) DEFAULT 0;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180824154912');
