ALTER TABLE `bugs` ADD `type` varchar(255) DEFAULT 'ResearchBug';
UPDATE bugs SET type = 'ResearchBug' where product = 'Research';
UPDATE bugs SET type = 'EscalationBug' where product = 'Escalations';
INSERT INTO `schema_migrations` (`version`) VALUES ('20180525191813');
