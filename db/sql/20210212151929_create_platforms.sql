CREATE TABLE `platforms` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `public_name` varchar(255), `internal_name` varchar(255), `webrep` tinyint(1) NOT NULL, `emailrep` tinyint(1) NOT NULL, `webcat` tinyint(1) NOT NULL, `filerep` tinyint(1) NOT NULL, `active` tinyint(1) DEFAULT TRUE NOT NULL, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL);
INSERT INTO `schema_migrations` (`version`) VALUES ('20210212151929');
ALTER TABLE `dispute_entries` ADD `platform_id` int;
ALTER TABLE `complaint_entries` ADD `platform_id` int;
ALTER TABLE `file_reputation_disputes` ADD `platform_id` int;
ALTER TABLE `disputes` ADD `platform_id` int;
ALTER TABLE `complaints` ADD `platform_id` int;
INSERT INTO `schema_migrations` (`version`) VALUES ('20210214014754');