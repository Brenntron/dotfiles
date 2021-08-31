CREATE TABLE `ngfw_clusters` (
  `id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `domain` varchar(191) CHARACTER SET utf8mb4,
  `traffic_hits` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT INTO `schema_migrations` (`version`) VALUES ('20210415113509');
