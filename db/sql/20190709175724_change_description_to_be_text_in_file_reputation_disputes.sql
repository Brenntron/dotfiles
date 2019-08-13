ALTER TABLE `file_reputation_disputes` MODIFY `description` text CHARACTER SET utf8mb4;
INSERT INTO `schema_migrations` (`version`) VALUES ('20190709175724');