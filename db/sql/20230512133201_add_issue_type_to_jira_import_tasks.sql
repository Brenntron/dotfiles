ALTER TABLE jira_import_tasks ADD COLUMN issue_type VARCHAR(255);

INSERT INTO `schema_migrations` (`version`) VALUES ('20230512133201');
