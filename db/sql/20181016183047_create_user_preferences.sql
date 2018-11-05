CREATE TABLE `user_preferences` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `user_id` bigint, `name` varchar(255), `value` text, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL,  INDEX `index_user_preferences_on_user_id`  (`user_id`)) ENGINE=InnoDB DEFAULT CHARACTER SET = utf8;
CREATE  INDEX `index_user_preferences_on_user_id`  ON `user_preferences` (`user_id`, `name`);
INSERT INTO `schema_migrations` (`version`) VALUES ('20181016183047');
