ALTER TABLE `dispute_entries` ADD `claim` varchar(255);
ALTER TABLE `dispute_entries` ADD `retries` int DEFAULT 0;
INSERT INTO `schema_migrations` (`version`) VALUES ('20230516132352');