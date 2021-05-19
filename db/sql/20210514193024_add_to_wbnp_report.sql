ALTER TABLE `wbnp_reports` ADD `status_message` varchar(255);
ALTER TABLE `wbnp_reports` ADD `attempts` int;
INSERT INTO `schema_migrations` (`version`) VALUES ('20210514193024');