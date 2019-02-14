CREATE TABLE `sessions` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `session_id` varchar(255) NOT NULL, `data` text, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB DEFAULT CHARACTER SET = utf8;
CREATE UNIQUE INDEX `index_sessions_on_session_id`  ON `sessions` (`session_id`);
CREATE  INDEX `index_sessions_on_updated_at`  ON `sessions` (`updated_at`);
INSERT INTO `schema_migrations` (`version`) VALUES ('20181030200738');
