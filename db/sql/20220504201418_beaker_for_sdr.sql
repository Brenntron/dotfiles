ALTER TABLE `sender_domain_reputation_disputes` ADD `beaker_info` mediumtext;
INSERT INTO `schema_migrations` (`version`) VALUES ('20220504201418');