ALTER TABLE `disputes` ADD `status_comment` text;

INSERT INTO `schema_migrations` (`version`) VALUES ('20181113170614’);
