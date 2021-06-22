ALTER TABLE `complaint_entry_credits` RENAME TO `webcat_credits`;
ALTER TABLE `webcat_credits` ADD `type` varchar(255);
ALTER TABLE `webcat_credits` ADD `domain` varchar(191) CHARACTER SET utf8mb4;
UPDATE `webcat_credits` SET `type`='ComplaintEntryCredit';
INSERT INTO `schema_migrations` (`version`) VALUES ('20210607095055');
