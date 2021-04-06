CREATE TABLE `cluster_categorizations` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `cluster_id` int, `comment` varchar(255), `category_ids` varchar(255), `user_id` int, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB;
CREATE  INDEX `index_cluster_categorizations_on_user_id`  ON `cluster_categorizations` (`user_id`);
INSERT INTO `schema_migrations` (`version`) VALUES ('20210312161720');
