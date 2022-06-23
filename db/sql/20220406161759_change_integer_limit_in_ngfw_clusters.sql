ALTER TABLE ngfw_clusters MODIFY traffic_hits BIGINT;
INSERT INTO `schema_migrations` (`version`) VALUES ('20220406161759');