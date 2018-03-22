ALTER TABLE `bugs` ADD `snort_secure` tinyint(1);
INSERT INTO `schema_migrations` (`version`) VALUES ('20180320143901');
