ALTER TABLE `sender_domain_reputation_disputes` ADD `priority` varchar(255);
ALTER TABLE `sender_domain_reputation_dispute_attachments` ADD `beaker_info` mediumtext;
INSERT INTO `schema_migrations` (`version`) VALUES ('20220420182813');
