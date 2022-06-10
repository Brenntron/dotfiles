ALTER TABLE `umbrella_clusters` ADD `traffic_hits` int DEFAULT 0;
INSERT INTO `schema_migrations` (`version`) VALUES ('20220607145233');
