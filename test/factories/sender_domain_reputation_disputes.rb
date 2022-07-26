FactoryBot.define do
  factory :sender_domain_reputation_dispute do
    customer_id           { 1 }
    user_id               { 1 }
    status                { SenderDomainReputationDispute::STATUS_NEW }
    platform_id           { 1 }
    sender_domain_entry   { 'test@google.com' }
    suggested_disposition { 'false negative' }
    source                { 'TI Webform' }
    submitter_type        { 'Customer' }
    beaker_info           { '{ “msg_guid”: “npVJ6UalRUymeOyWTGNcpQ==“, “threat_level_id”: 4, “query_ts” 1651163073492, “threat_cat_map_version”: 3, “threat_level_map_version”: 1, “service_data”: [ { “service_name”: “kqed”, “message_type”: “talos.sdr.talosresults.Results”, “data”: { “result”: [ { “resultType”: “RESULT_HDR_FROM”, “mailbox”: { “addr”: “cisco.com”, “display”: “” }, “ruleHitId”: [ 57, 376, 345, 341 ], “reputationScoreX10”: 370, “noReputationScore”: false, “threatCatId”: [], “domainMaturityLevelId”: 0 } ] } } ], “sender_maturity_timestamp”: 1648484673, “least_mature_sender”: “cisco.com” }' }
  end
end
