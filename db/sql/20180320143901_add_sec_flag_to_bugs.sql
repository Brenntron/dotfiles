ALTER TABLE `bugs` ADD `snort_secure` tinyint(1) DEFAULT 0;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180320143901');
UPDATE `bugs` SET `snort_secure` = 0;
