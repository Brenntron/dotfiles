ALTER TABLE jira_import_tasks ADD COLUMN issue_summary TEXT;
ALTER TABLE jira_import_tasks ADD COLUMN issue_description TEXT;
ALTER TABLE jira_import_tasks ADD COLUMN issue_platform VARCHAR(255);
ALTER TABLE jira_import_tasks ADD COLUMN issue_status VARCHAR(255);

INSERT INTO `schema_migrations` (`version`) VALUES ('20230505113455');
