CREATE TABLE `jira_import_tasks` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `issue_key` varchar(255) NOT NULL, `status` varchar(255), `result` varchar(255), `submitter` varchar(255), `bast_task` int, `imported_at` datetime, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL);
INSERT INTO `schema_migrations` (`version`) VALUES ('20230321140649');
