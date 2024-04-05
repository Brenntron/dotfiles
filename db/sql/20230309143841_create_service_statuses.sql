CREATE TABLE `service_statuses` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `name` varchar(255), `model` varchar(255), `exception_count` int, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL);
INSERT INTO `schema_migrations` (`version`) VALUES ('20230309143841');
CREATE TABLE `service_status_logs` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `service_status_id` int, `exception` mediumtext, `exception_details` mediumtext, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL);
INSERT INTO `schema_migrations` (`version`) VALUES ('20230309143851');