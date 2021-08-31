
ALTER TABLE `cluster_assignments` DROP `cluster_id`;
ALTER TABLE `cluster_assignments` ADD `domain` varchar(255);
INSERT INTO `schema_migrations` (`version`) VALUES ('20210505132123');
