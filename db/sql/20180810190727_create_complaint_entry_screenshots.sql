CREATE TABLE `complaint_entry_screenshots` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL, `complaint_entry_id` int, `screenshot` mediumblob) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
CREATE  INDEX `index_complaint_entry_screenshots_on_complaint_entry_id`  ON `complaint_entry_screenshots` (`complaint_entry_id`);
INSERT INTO `schema_migrations` (`version`) VALUES ('20180810190727');
