ALTER TABLE `complaint_entries` ADD `category` varchar(255);
ALTER TABLE `complaint_entries` ADD `is_important` int;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180530201337');

