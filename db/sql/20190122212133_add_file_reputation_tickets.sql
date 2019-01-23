
CREATE TABLE `file_reputation_tickets` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `customer_id` int, `status` varchar(255),`source` varchar(255),`platform` varchar(255),`description` varchar(255),`reputation_file` int) ENGINE=InnoDB;
CREATE TABLE `reputation_file` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `bugzilla_attachment_id` int,`sha256` varchar(255) UNIQUE,`file_path` varchar(255),`file_name` varchar(255) ) ENGINE=InnoDB;
CREATE TABLE `immunet_false_positives` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `version` varchar(255) ) ENGINE=InnoDB;

DROP TABLE `amp_false_positive_files`;

CREATE TABLE `amp_false_positives` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `payload` text, `file_reputation_ticket_id` bigint , `sr_id` int) ENGINE=InnoDB;

CREATE INDEX index_amp_false_positives_on_file_reputation_ticket_id ON amp_false_positives (file_reputation_ticket_id);
CREATE INDEX index_amp_false_positives_on_payload ON amp_false_positives (payload(15));

CREATE INDEX index_file_reputation_tickets_on_customer_id ON file_reputation_tickets (customer_id);
CREATE INDEX index_file_reputation_tickets_on_reputation_file_id ON file_reputation_tickets (reputation_file_id);


INSERT INTO `schema_migrations` (`version`) VALUES ('20181219125445');