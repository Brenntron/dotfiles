ALTER TABLE `rules` ADD `snort_doc_status` varchar(255) DEFAULT 'NOTYET';
INSERT INTO `schema_migrations` (`version`) VALUES ('20171208211012');
