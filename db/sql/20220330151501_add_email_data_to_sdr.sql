ALTER TABLE `sender_domain_reputation_dispute_attachments` ADD `email_header_data` text;
INSERT INTO `schema_migrations` (`version`) VALUES ('20220330151501');
