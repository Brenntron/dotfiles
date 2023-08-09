-- Update resolution_message_templates table
UPDATE resolution_message_templates SET description = 'FIXED_FP' WHERE description = 'Fixed - FP' and status = 1;
UPDATE resolution_message_templates SET description = 'FIXED_FN' WHERE description = 'Fixed - FN' and status = 1;
UPDATE resolution_message_templates SET description = 'UNCHANGED' WHERE description = 'Unchanged' and status = 1;
UPDATE resolution_message_templates SET description = 'INVALID' WHERE description = 'Invalid / Junk Mail' and status = 1;
UPDATE resolution_message_templates SET description = 'TEST_TRAINING' WHERE description = 'Test / Training' and status = 1;
UPDATE resolution_message_templates SET description = 'OTHER' WHERE description = 'Other' and status = 1;

-- update disputes table
UPDATE disputes SET resolution = 'FIXED_FP' WHERE resolution = 'Fixed - FP';
UPDATE disputes SET resolution = 'FIXED_FN' WHERE resolution = 'Fixed - FN';
UPDATE disputes SET resolution = 'INVALID' WHERE resolution = 'Invalid / Junk Mail';
UPDATE disputes SET resolution = 'TEST_TRAINING' WHERE resolution = 'Test / Training';
-- MySql search is not case sensitive, so no need to update all old records, for that we need to use 'BINARY' option
UPDATE disputes SET resolution = 'UNCHANGED' WHERE  BINARY resolution = 'Unchanged';
UPDATE disputes SET resolution = 'OTHER' WHERE  BINARY resolution = 'Other';
