ALTER TABLE `dispute_entries` ADD `proxy_url` text;
ALTER TABLE `dispute_entries` ADD `multi_wbrs_threat_category` text;
ALTER TABLE `dispute_entries` ADD `wbrs_threat_category` text;
ALTER TABLE `dispute_entry_preloads` ADD `multi_wbrs_threat_category` text;
INSERT INTO `schema_migrations` (`version`) VALUES ('20200205193134');