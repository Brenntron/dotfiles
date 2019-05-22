ALTER TABLE `file_reputation_disputes` ADD `reversing_labs_raw` mediumtext;
INSERT INTO `schema_migrations` (`version`) VALUES ('20190510170412');
