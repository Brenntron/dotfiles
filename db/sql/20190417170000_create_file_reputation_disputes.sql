CREATE TABLE `file_reputation_disputes` (
    `id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `created_at` datetime NOT NULL,
    `updated_at` datetime NOT NULL,
    `customer_id` bigint, `status` varchar(255) DEFAULT 'NEW' NOT NULL,
    `source` varchar(255),
    `platform` varchar(255),
    `description` varchar(255),
    `file_name` varchar(255),
    `file_size` int,
    `sha256_hash` varchar(255),
    `sample_type` varchar(255),
    `disposition` varchar(255),
    `disposition_suggested` varchar(255),
    `user_id` bigint, `sandbox_score` float(24),
    `sandbox_threshold` float(24),
    `sandbox_signer` varchar(255),
    `has_sample` tinyint(1),
    `in_zoo` tinyint(1),
    `threatgrid_score` float(24),
    `threatgrid_threshold` float(24),
    `threatgrid_signer` varchar(255),
    `threatgrid_private` tinyint(1),
    `reversing_labs_score` int,
    `reversing_labs_signer` varchar(255),
    `resolution` varchar(255),
    `detection_name` varchar(255),
    `detection_created_at` datetime,
    `case_closed_at` datetime,
    `case_responded_at` datetime,
    INDEX `index_file_reputation_disputes_on_created_at`  (`created_at`),
    INDEX `index_file_reputation_disputes_on_customer_id`  (`customer_id`),
    INDEX `index_file_reputation_disputes_on_sha256_hash`  (`sha256_hash`),
    INDEX `index_file_reputation_disputes_on_updated_at`  (`updated_at`),
    INDEX `index_file_reputation_disputes_on_user_id`  (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO `schema_migrations` (`version`) VALUES ('20190122211756');
INSERT INTO `schema_migrations` (`version`) VALUES ('20190301184911');
INSERT INTO `schema_migrations` (`version`) VALUES ('20190405132032');
INSERT INTO `schema_migrations` (`version`) VALUES ('20190408203516');
INSERT INTO `schema_migrations` (`version`) VALUES ('20190409132737');
INSERT INTO `schema_migrations` (`version`) VALUES ('20190409201329');
INSERT INTO `schema_migrations` (`version`) VALUES ('20190415150046');
INSERT INTO `schema_migrations` (`version`) VALUES ('20190416144436');
INSERT INTO `schema_migrations` (`version`) VALUES ('20190417165456');
