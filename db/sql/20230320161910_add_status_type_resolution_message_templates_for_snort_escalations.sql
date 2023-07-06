ALTER TABLE `resolution_message_templates` ADD `creator_id` int;
ALTER TABLE `resolution_message_templates` ADD `editor_id` int;
ALTER TABLE `resolution_message_templates` ADD `resolution_type` varchar(255);

INSERT INTO `schema_migrations` (`version`) VALUES ('20230320161910');
