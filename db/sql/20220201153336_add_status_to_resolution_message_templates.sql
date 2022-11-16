ALTER TABLE `resolution_message_templates` ADD `status` int;
INSERT INTO `resolution_message_templates` (`name`, `description`, `body`, `created_at`, `updated_at`, `status`) VALUES
('Fixed - FP', 'Fixed - FP', 'Talos has concluded that the submission is safe to access at this time; the submission’s reputation has been improved. This update will be publicly visible in the next 24 hours.', '2022-03-23 17:52:41', '2022-03-23 17:52:41', 1),
('Fixed - FN', 'Fixed - FN', 'Talos has concluded that the submission is unsafe to access at this time due to malicious activity; the submission’s reputation has been decreased. This update will be publicly visible in the next 24 hours.', '2022-03-23 17:52:41', '2022-03-23 17:52:41', 1),
('Unchanged', 'Unchanged', 'Talos has not found sufficient evidence to modify the current reputation of the submission; we cannot change the submission’s reputation because it can negatively affect our customers. However, a customer has the option of locally changing a submission’s reputation, if they understand the risks in doing so.', '2022-03-23 17:52:41', '2022-03-23 17:52:41', 1),
('Invalid / Junk Mail', 'Invalid / Junk Mail', '', '2022-03-23 17:52:41', '2022-03-23 17:52:41', 1),
('Test / Training', 'Test / Training', '', '2022-03-23 17:52:41', '2022-03-23 17:52:41', 1),
('Other', 'Other', '', '2022-03-23 17:52:41', '2022-03-23 17:52:41', 1);
INSERT INTO `schema_migrations` (`version`) VALUES ('20220201153336');