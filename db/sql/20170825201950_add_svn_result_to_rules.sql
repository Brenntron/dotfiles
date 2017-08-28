ALTER TABLE `rules` ADD `svn_result_output` text;
ALTER TABLE `rules` ADD `svn_result_code` int;
ALTER TABLE `rules` ADD `svn_success` tinyint(1);
INSERT INTO `schema_migrations` (`version`) VALUES ('20170825201950');
