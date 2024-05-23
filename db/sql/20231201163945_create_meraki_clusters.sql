CREATE TABLE `meraki_clusters` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `domain` varchar(255) COLLATE utf8mb4_0900_ai_ci, `platform_id` bigint, `category_ids` varchar(255), `status` int DEFAULT 0, `traffic_hits` bigint DEFAULT 0, `comment` varchar(255), `created_at` datetime(6) NOT NULL, `updated_at` datetime(6) NOT NULL, INDEX `index_meraki_clusters_on_platform_id` (`platform_id`));
INSERT INTO `schema_migrations` (`version`) VALUES ('20231201163945');