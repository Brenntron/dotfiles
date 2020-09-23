ALTER TABLE `dispute_entries` ADD `platform` varchar(255);
ALTER TABLE `complaint_entries` ADD `platform` varchar(255);
INSERT INTO `schema_migrations` (`version`) VALUES ('20200819195017');
