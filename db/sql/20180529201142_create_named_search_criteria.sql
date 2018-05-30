CREATE TABLE `named_search_criteria` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL, `named_search_id` int, `field_name` varchar(255), `value` varchar(255)) ENGINE=InnoDB DEFAULT CHARACTER SET = utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180529201142');
