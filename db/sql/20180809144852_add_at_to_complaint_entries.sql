ALTER TABLE `complaint_entries` ADD `case_resolved_at` datetime;
ALTER TABLE `complaint_entries` ADD `case_assigned_at` datetime;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180809144852');
