ALTER TABLE `file_reputation_disputes` CHANGE `submitter_type` `sandbox_key` varchar(255);
INSERT INTO `schema_migrations` (`version`) VALUES ('20190708175758');

ALTER TABLE `file_reputation_disputes` ADD `submitter_type` varchar(255);
INSERT INTO `schema_migrations` (`version`) VALUES ('20190708175847');


