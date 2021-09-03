ALTER TABLE `disputes` ADD `meta_data` mediumtext;
ALTER TABLE `complaints` ADD `meta_data` mediumtext;
ALTER TABLE `file_reputation_disputes` ADD `meta_data` mediumtext;
INSERT INTO `schema_migrations` (`version`) VALUES ('20210423154426');