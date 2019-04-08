ALTER TABLE `file_reputation_disputes` ADD `user_id` bigint;
CREATE  INDEX `index_file_reputation_disputes_on_user_id`  ON `file_reputation_disputes` (`user_id`);
INSERT INTO `schema_migrations` (`version`) VALUES ('20190408203516');
