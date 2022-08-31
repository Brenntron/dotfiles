ALTER TABLE `sender_domain_reputation_disputes` ADD `case_responded_at` datetime;
INSERT INTO `schema_migrations` (`version`) VALUES ('20220502184215');
