CREATE TABLE `user_api_keys` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL, `user_id` int, `api_key` varchar(255)) ENGINE=InnoDB;
CREATE UNIQUE INDEX `index_user_api_keys_on_api_key`  ON `user_api_keys` (`api_key`);
INSERT INTO `schema_migrations` (`version`) VALUES ('20171218170458');
INSERT INTO `user_api_keys` (`created_at`, `updated_at`, `user_id`, `api_key`) VALUES ('2017-12-19 16:58:55', '2017-12-19 16:58:55', 273, 'FZ4bhccl9M99EMY9+0rY7Zm5Er4nhReumOg/HzpDTAo1aObHltZbljhfApa5WzMcySKq3jpyDRzBYxJc');
