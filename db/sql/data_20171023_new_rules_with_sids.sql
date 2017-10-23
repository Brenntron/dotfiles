update rules set edit_status = 'SYNCHED' where sid is not null AND state = 'UNCHANGED';
