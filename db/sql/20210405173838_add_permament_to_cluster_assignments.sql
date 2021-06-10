ALTER TABLE `cluster_assignments` ADD `permanent` boolean DEFAULT FALSE NOT NULL;
INSERT INTO `schema_migrations` (`version`) VALUES ('20210405173838');
