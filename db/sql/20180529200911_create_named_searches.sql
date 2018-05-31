CREATE TABLE `named_searches` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL, `user_id` int, `name` varchar(255)) ENGINE=InnoDB DEFAULT CHARACTER SET = utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180529200911');
