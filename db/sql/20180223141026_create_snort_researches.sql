CREATE TABLE `escalations` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `snort_research_escalation_bug_id` int, `snort_escalation_research_bug_id` int, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180214165049');
CREATE TABLE `snort_researches` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `bug_id` int, `snort_research_to_research_bug_id` int, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180223141026');
