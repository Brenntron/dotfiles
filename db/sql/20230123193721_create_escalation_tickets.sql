CREATE TABLE `escalation_tickets` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `ticket_data` mediumtext, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL);
INSERT INTO `schema_migrations` (`version`) VALUES ('20230123193721');