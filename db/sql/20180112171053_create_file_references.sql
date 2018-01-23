CREATE TABLE `file_references` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL, `type` varchar(255), `file_name` varchar(255), `location` text, `file_type_name` varchar(255), `source` varchar(255)) ENGINE=InnoDB;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180112171053');
