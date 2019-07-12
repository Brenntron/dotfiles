CREATE TABLE `wbnp_reports` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `total_new_cases` int, `cases_imported` int, `cases_failed` int, `status` varchar(255), `notes` mediumtext, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL);
INSERT INTO `schema_migrations` (`version`) VALUES ('20190607133955');
