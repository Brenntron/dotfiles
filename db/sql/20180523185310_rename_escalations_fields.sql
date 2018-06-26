RENAME TABLE `escalations` TO `escalation_links`;
ALTER TABLE `escalation_links` CHANGE `snort_escalation_research_bug_id` `snort_escalation_bug_id` int(11) DEFAULT NULL;
ALTER TABLE `escalation_links` CHANGE `snort_research_escalation_bug_id` `snort_research_bug_id` int(11) DEFAULT NULL;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180523185310');
