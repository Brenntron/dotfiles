-- Cretate common company and customer for JIRA imports
INSERT INTO companies (name, created_at, updated_at) VALUES ('ACE JIRA IMPORTS', '2023-04-28 12:00:00', '2023-04-28 12:00:00');

INSERT INTO customers (company_id, email, name, created_at, updated_at) 
VALUES (
  (SELECT id FROM companies WHERE name = 'ACE JIRA IMPORTS' LIMIT 1), 
  'ace-jira.gen@cisco.com', 
  'ACE JIRA IMPORTS',
  '2023-04-28 12:00:00', 
  '2023-04-28 12:00:00'
);
