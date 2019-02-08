ALTER TABLE `complaint_entries` CHANGE `category` `category` varchar(2000) DEFAULT NULL;
ALTER TABLE `complaint_entries` CHANGE `url_primary_category` `url_primary_category` varchar(2000) DEFAULT NULL;
INSERT INTO `schema_migrations` (`version`) VALUES ('20190204142309');