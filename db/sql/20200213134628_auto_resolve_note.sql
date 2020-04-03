ALTER TABLE `file_reputation_disputes` ADD `auto_resolve_log` text;
ALTER TABLE `dispute_entries` ADD `auto_resolve_log` text;
INSERT INTO `schema_migrations` (`version`) VALUES ('20200213134628');
