ALTER TABLE `references` CHANGE `reference_data` `reference_data` text DEFAULT NULL;
INSERT INTO `schema_migrations` (`version`) VALUES ('20171208175552');
