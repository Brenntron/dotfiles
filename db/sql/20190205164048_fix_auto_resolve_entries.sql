UPDATE `dispute_entries`
INNER JOIN `disputes` ON `disputes`.`id` = `dispute_entries`.`dispute_id`
SET `dispute_entries`.`status` = "RESOLVED_CLOSED"
WHERE
`disputes`.`resolution` = 'All Auto Resolved'