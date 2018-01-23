CREATE TABLE `fp_file_refs` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL, `false_positive_id` int, `file_reference_id` int) ENGINE=InnoDB;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180109194224');
