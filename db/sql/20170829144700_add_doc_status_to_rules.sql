ALTER TABLE `rules` ADD `doc_status` varchar(255) DEFAULT 'New' NOT NULL;
INSERT INTO `schema_migrations` (`version`) VALUES ('20170829144700');
