ALTER TABLE `platforms` ADD `senderdomain` tinyint(1);
INSERT INTO `schema_migrations` (`version`) VALUES ('20220627164835');