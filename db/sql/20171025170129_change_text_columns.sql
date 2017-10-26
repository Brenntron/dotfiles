ALTER TABLE `bugs` CHANGE `description` `description` text DEFAULT NULL;
ALTER TABLE `bugs` CHANGE `summary` `summary` text DEFAULT NULL;
INSERT INTO `schema_migrations` (`version`) VALUES ('20171025170129');
