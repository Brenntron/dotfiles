ALTER TABLE `disputes` ADD `bridge_packet` mediumtext;
ALTER TABLE `disputes` ADD `import_log` mediumtext;
ALTER TABLE `complaints` ADD `bridge_packet` mediumtext;
ALTER TABLE `complaints` ADD `import_log` mediumtext;
ALTER TABLE `file_reputation_disputes` ADD `bridge_packet` mediumtext;
ALTER TABLE `file_reputation_disputes` ADD `import_log` mediumtext;
INSERT INTO `schema_migrations` (`version`) VALUES ('20210326174523');