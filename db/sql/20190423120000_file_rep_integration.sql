ALTER TABLE `users` ADD `threatgrid_api_key` varchar(255);
ALTER TABLE `users` ADD `sandbox_api_key` varchar(255);
INSERT INTO `schema_migrations` (`version`) VALUES ('20190410205212');
CREATE TABLE `file_rep_comments` (
    `id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `created_at` datetime NOT NULL,
    `updated_at` datetime NOT NULL,
    `file_reputation_dispute_id` bigint NOT NULL,
    `user_id` bigint NOT NULL,
    `comment` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATE INDEX index_file_rep_comments_on_file_reputation_dispute_id ON file_rep_comments (file_reputation_dispute_id, user_id);
INSERT INTO `schema_migrations` (`version`) VALUES ('20190411153233');
ALTER TABLE `dispute_emails` ADD `file_reputation_dispute_id` bigint;
CREATE INDEX index_dispute_emails_on_file_reputation_dispute_id ON dispute_emails (file_reputation_dispute_id);
INSERT INTO `schema_migrations` (`version`) VALUES ('20190415151221');
CREATE TABLE `digital_signers` (
    `id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `created_at` datetime NOT NULL,
    `updated_at` datetime NOT NULL,
    `file_reputation_dispute_id` bigint NOT NULL,
    `issuer` varchar(255),
    `subject` varchar(255),
    `valid_from` datetime,
    `valid_to` datetime
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATE INDEX index_digital_signers_on_file_reputation_dispute_id ON digital_signers (file_reputation_dispute_id);
INSERT INTO `schema_migrations` (`version`) VALUES ('20190416172411');
ALTER TABLE `file_reputation_disputes` ADD `reversing_labs_count` int;
INSERT INTO `schema_migrations` (`version`) VALUES ('20190422145106');

