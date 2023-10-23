set @subset_id = (select id from org_subsets where name = 'webcat');
insert into roles (role, org_subset_id) values ('tmi viewer', @subset_id);
insert into roles (role, org_subset_id) values ('tmi manager', @subset_id);
INSERT INTO `schema_migrations` (`version`) VALUES ('20230705140515');
