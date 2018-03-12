CREATE TABLE `bug_blockers` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `snort_blocker_bug_id` int, `snort_blocked_bug_id` int, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180227144858');
