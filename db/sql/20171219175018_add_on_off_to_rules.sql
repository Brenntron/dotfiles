ALTER TABLE `rules` ADD `snort_on_off` varchar(255) DEFAULT 'on';
INSERT INTO `schema_migrations` (`version`) VALUES ('20171219175018');
