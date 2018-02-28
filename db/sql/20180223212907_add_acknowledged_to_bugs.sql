INSERT INTO `schema_migrations` (`version`) VALUES ('20180223212907');
ALTER TABLE `bugs` ADD `acknowledged` BOOLEAN DEFAULT '0';