ALTER TABLE `file_reputation_disputes` ADD `last_fetched` datetime
ALTER TABLE `file_reputation_disputes` CHANGE `detection_created_at` `detection_last_set` datetime DEFAULT NULL
INSERT INTO `schema_migrations` (`version`) VALUES ('20190610190020')