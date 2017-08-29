ALTER TABLE `tasks` CHANGE `result` `result` mediumtext DEFAULT NULL
INSERT INTO `schema_migrations` (`version`) VALUES ('20170829145347')