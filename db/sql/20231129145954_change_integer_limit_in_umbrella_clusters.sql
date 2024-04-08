ALTER TABLE umbrella_clusters MODIFY traffic_hits BIGINT;
INSERT INTO `schema_migrations` (`version`) VALUES ('20231129145954');