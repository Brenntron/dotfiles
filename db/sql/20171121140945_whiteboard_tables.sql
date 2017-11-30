CREATE TABLE `giblets` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `bug_id` int, `name` varchar(255), `gib_type` varchar(255), `gib_id` bigint,  INDEX `index_giblets_on_gib_type_and_gib_id`  (`gib_type`, `gib_id`)) ENGINE=InnoDB
CREATE TABLE `whiteboards` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `name` varchar(255) NOT NULL, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB;
CREATE TABLE `bugs_whiteboards` (`bug_id` bigint NOT NULL, `whiteboard_id` bigint NOT NULL,  INDEX `index_bugs_whiteboards_on_bug_id`  (`bug_id`),  INDEX `index_bugs_whiteboards_on_whiteboard_id`  (`whiteboard_id`)) ENGINE=InnoDB;
CREATE UNIQUE INDEX `index_bugs_whiteboards_on_bug_id_and_whiteboard_id`  ON `bugs_whiteboards` (`bug_id`, `whiteboard_id`);
CREATE TABLE `morsels` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `output` text, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB;
INSERT INTO `schema_migrations` (`version`) VALUES ('20171120130757')
INSERT INTO `schema_migrations` (`version`) VALUES ('20171121135557');
INSERT INTO `schema_migrations` (`version`) VALUES ('20171121140945');
INSERT INTO `schema_migrations` (`version`) VALUES ('20171122160533');
