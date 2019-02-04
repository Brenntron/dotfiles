ALTER TABLE `named_searches` ADD `project_type` varchar(255);

INSERT INTO `schema_migrations` (`version`) VALUES ('20190124190010');