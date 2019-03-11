CREATE TABLE `file_reps` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL, `file_rep_name` varchar(255), `sha256` text, `email` varchar(255)) DEFAULT CHARACTER SET = utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20190301184911');
