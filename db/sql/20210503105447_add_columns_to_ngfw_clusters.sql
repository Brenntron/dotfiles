ALTER TABLE `ngfw_clusters` ADD `platform_id` int;
ALTER TABLE `ngfw_clusters` ADD `category_ids` varchar(255);
ALTER TABLE `ngfw_clusters` ADD `status` int DEFAULT 0;
ALTER TABLE `ngfw_clusters` ADD `comment` varchar(255);
CREATE  INDEX `index_ngfw_clusters_on_platform_id`  ON `ngfw_clusters` (`platform_id`);
INSERT INTO `schema_migrations` (`version`) VALUES ('20210503105447');
