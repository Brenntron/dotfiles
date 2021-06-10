CREATE TABLE `complaint_entry_credits` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `credit` varchar(255), `user_id` int, `complaint_entry_id` int, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB;
CREATE  INDEX `index_complaint_entry_credits_on_complient_entry_id`  ON `complaint_entry_credits` (`user_id`);
CREATE  INDEX `index_complaint_entry_credits_on_user_id`  ON `complaint_entry_credits` (`complaint_entry_id`);
INSERT INTO `schema_migrations` (`version`) VALUES ('20210112173920');
