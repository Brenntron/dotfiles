ALTER TABLE `complaint_entries` ADD `abuse_information` text;
INSERT INTO `schema_migrations` (`version`) VALUES ('20230719185330');
CREATE TABLE `abuse_records` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `complaint_entry_id` int, `source` varchar(255), `report_ident` varchar(255), `result` text, `report_submitted` text, `submitter` varchar(255), `url` text, `created_at` datetime(6) NOT NULL, `updated_at` datetime(6) NOT NULL);
INSERT INTO `schema_migrations` (`version`) VALUES ('20240205012919');