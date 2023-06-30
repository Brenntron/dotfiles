ALTER TABLE `complaint_entries` ADD `reviewer_id` int;
ALTER TABLE `complaint_entries` ADD `second_reviewer_id` int;
INSERT INTO `schema_migrations` (`version`) VALUES ('20230328143918');
