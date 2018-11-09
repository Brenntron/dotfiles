CREATE TABLE `amp_false_positives` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL, 'sha256' varchar(255), 'customer_id' int, 'source' varchar(255), 'description' text, 'product' varchar(255), 'sr_id' int, 'payload' text) ENGINE=InnoDB;
CREATE UNIQUE INDEX `index_amp_false_positives_on_payload`  ON `amp_false_positives` ( `payload`(15));
CREATE UNIQUE INDEX `index_amp_false_positives_on_sha256`  ON `amp_false_positives` ( `sha256`);
INSERT INTO `schema_migrations` (`version`) VALUES ('20181107195956');