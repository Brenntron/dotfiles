CREATE TABLE `saved_searches` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `session_query` text, `session_search` text, `name` varchar(255), `user_id` int, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB;
INSERT INTO `schema_migrations` (`version`) VALUES ('20171019140610');
