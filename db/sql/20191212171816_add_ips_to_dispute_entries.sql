INSERT INTO `schema_migrations` (`version`) VALUES ('20191212171816');
ALTER TABLE `dispute_rule_hits` ADD `is_multi_ip_rulehit` tinyint(1);
ALTER TABLE `dispute_entries` ADD `web_ips` text;

