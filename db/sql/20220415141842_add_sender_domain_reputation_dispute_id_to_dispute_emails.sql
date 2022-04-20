ALTER TABLE `dispute_emails` ADD `sender_domain_reputation_dispute_id` int;
INSERT INTO `schema_migrations` (`version`) VALUES ('20220415141842');