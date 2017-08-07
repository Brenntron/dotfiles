INSERT INTO `schema_migrations` (`version`) VALUES ('20170801120000');
ALTER TABLE `tasks` ADD `type` varchar(255) DEFAULT 'Task';
INSERT INTO `schema_migrations` (`version`) VALUES ('20170807140953');
