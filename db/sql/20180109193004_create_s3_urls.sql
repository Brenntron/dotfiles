CREATE TABLE `s3_urls` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL, `url` text, `file_name` varchar(255), `file_type_name` varchar(255)) ENGINE=InnoDB;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180109193004');
