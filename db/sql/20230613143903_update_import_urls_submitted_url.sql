ALTER TABLE `import_urls` CHANGE `submitted_url` `submitted_url` text DEFAULT NULL;
INSERT INTO `schema_migrations` (`version`) VALUES ('20230613143903');