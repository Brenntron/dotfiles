CREATE TABLE `import_urls` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `jira_import_task_id` int, `submitted_url` varchar(255), `domain` varchar(255), `bast_status` varchar(255), `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL);
INSERT INTO `schema_migrations` (`version`) VALUES ('20230321143104');
