INSERT INTO org_subsets (name, created_at, updated_at) values
   ('file rep', now(), now())
;

INSERT INTO roles (name, org_subset_id) values
   ('filerep manager', LAST_INSERT_ID()),
   ('filerep user'), LAST_INSERT_ID())
;