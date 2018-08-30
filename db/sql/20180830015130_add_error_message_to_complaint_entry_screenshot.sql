ALTER TABLE `complaint_entry_screenshots` ADD `error_message` varchar(255) DEFAULT '' ;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180830015130');
