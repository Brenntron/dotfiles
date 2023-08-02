ALTER TABLE `import_urls` ADD `complaint_id` int;
ALTER TABLE `import_urls` ADD `verdict_reason` varchar(255);
ALTER TABLE `import_urls` RENAME COLUMN `bast_status` TO `bast_verdict`;
INSERT INTO `schema_migrations` (`version`) VALUES ('20230419175059');
