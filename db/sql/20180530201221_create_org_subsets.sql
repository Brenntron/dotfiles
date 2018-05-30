CREATE TABLE `org_subsets` (`id` bigint NOT NULL AUTO_INCREMENT PRIMARY KEY, `name` varchar(255), `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL) ENGINE=InnoDB DEFAULT CHARACTER SET = utf8;
INSERT INTO org_subsets (name, created_at, updated_at) values
   ('admin', now(), now()),
   ('ips rules', now(), now()),
   ('ips escalator', now(), now()),
   ('web cat', now(), now()),
   ('web rep', now(), now())
;
INSERT INTO `schema_migrations` (`version`) VALUES ('20180530201221');
