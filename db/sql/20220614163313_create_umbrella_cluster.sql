CREATE TABLE `umbrella_clusters` (
  `id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `domain` varchar(191) CHARACTER SET utf8mb4,
  `platform_id` int,
  `category_ids` varchar(255),
  `status` int DEFAULT 0,
  `traffic_hits` int DEFAULT 0,
  `comment` varchar(255)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE  INDEX `index_umbrella_clusters_on_platform_id`  ON `umbrella_clusters` (`platform_id`);
INSERT INTO `schema_migrations` (`version`) VALUES ('20220614163313');
