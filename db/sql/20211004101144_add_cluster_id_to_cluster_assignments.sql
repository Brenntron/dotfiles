ALTER TABLE `cluster_assignments` ADD `cluster_id` int;
INSERT INTO `schema_migrations` (`version`) VALUES ('20211004101144');
