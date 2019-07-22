ALTER TABLE `file_reputation_disputes` ADD `case_closed_at` datetime;
INSERT INTO `schema_migrations` (`version`) VALUES ('20190415150046');
ALTER TABLE `dispute_emails` ADD `file_reputation_dispute_id` int;
INSERT INTO `schema_migrations` (`version`) VALUES ('20190415151221');
