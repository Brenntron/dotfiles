ALTER TABLE `disputes` ADD `resolution_comment` text;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180822195617');