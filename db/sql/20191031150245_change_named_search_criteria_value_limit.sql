ALTER TABLE `named_search_criteria` CHANGE `value` `value` TEXT DEFAULT NULL;
INSERT INTO `schema_migrations` (`version`) VALUES ('20191031150245');