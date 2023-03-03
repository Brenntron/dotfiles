ALTER TABLE `resolution_message_templates` ADD `ticket_type` varchar(255);
UPDATE `resolution_message_templates` SET ticket_type = 'Dispute';
INSERT INTO `schema_migrations` (`version`) VALUES ('20230303093056');
