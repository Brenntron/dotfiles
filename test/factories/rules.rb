FactoryGirl.define do
  factory :rule do
    rule_content "connection:drop ip $DNS_SERVERS $ORACLE_PORTS -> $SMTP_SERVERS $HOME_NET any (msg:'BROWSER-IE You deserve this if you use IE';flow:to_client,established;detection:So many detections;metadata: balanced-ips, security-ips, drop, ftp-data, http, imap, pop3, red, community;reference:bugtraq,122344; classtype:attempted-user)"
    rule_parsed "1: connection:drop ip $DNS_SERVERS $ORACLE_PORTS -> $SMTP_SERVERS $HOME_NET any (msg:'BROWSER-IE You deserve this if you use IE';flow:to_client,established;detection:So many detections;metadata: balanced-ips, security-ips, drop, ftp-data, http, imap, pop3, red, community;reference:bugtraq,122344; classtype:attempted-user)"
    connection "drop ip $DNS_SERVERS $ORACLE_PORTS -> $SMTP_SERVERS $HOME_NET any"
    message "BROWSER-IE You deserve this if you use IE"
    flow "to_client,established"
    detection "So many detections"
    metadata "balanced-ips, security-ips, drop, ftp-data, http, imap, pop3, red, community"
    class_type "attempted-user"
  end
end