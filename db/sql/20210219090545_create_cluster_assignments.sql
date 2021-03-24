CREATE TABLE `cluster_assignments` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `cluster_id` int, `user_id` int, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB;
CREATE  INDEX `index_cluster_assignments_on_user_id`  ON `cluster_assignments` (`user_id`);
INSERT INTO `schema_migrations` (`version`) VALUES ('20210219090545');
