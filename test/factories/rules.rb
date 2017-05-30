FactoryGirl.define do
  factory :rule do
    rule_content "alert tcp $EXTERNAL_NET $FILE_DATA_PORTS -> $HOME_NET any (msg:\"BROWSER-PLUGINS Microsoft Internet Explorer MSXML .definition ActiveX clsid access attempt\"; flow:to_client,established; file_data; content:\"Msxml2.FreeThreadedDOMDocument.6.0\"; fast_pattern:only; content:\".definition(\"; nocase; pcre:\"/(var|set)\\s+\\w+\\s*=\\s*(new\\s+ActiveXObject|CreateObject)\\s*\\((?P<q1>(\\x22|\\x27|))Msxml2\\.FreeThreadedDOMDocument\\.6\\.0(?P=q1)\\)/smi\"; metadata:policy balanced-ips drop, policy security-ips drop, service ftp-data, service http, service imap, service pop3; reference:cve,2012-1889; reference:url,technet.microsoft.com/en-us/security/bulletin/ms12-043; classtype:attempted-user; sid:23304; rev:4;)"
    rule_parsed "Connection: alert tcp $EXTERNAL_NET $FILE_DATA_PORTS -> $HOME_NET any\nMessage   : BROWSER-PLUGINS Microsoft Internet Explorer MSXML .definition ActiveX clsid access attempt\nFlow      : to_client,established\nDetection :\n\tfile_data;\n\tcontent:\"Msxml2.FreeThreadedDOMDocument.6.0\"; fast_pattern:only;\n\tcontent:\".definition(\"; nocase;\n\tpcre:\"/(var|set)\\s+\\w+\\s*=\\s*(new\\s+ActiveXObject|CreateObject)\\s*\\((?P<q1>(\\x22|\\x27|))Msxml2\\.FreeThreadedDOMDocument\\.6\\.0(?P=q1)\\)/smi\";\nMetadata  :\n\tPolicy: balanced-ips drop, security-ips drop\n\tService: ftp-data, imap, pop3, http\nReferences:\n\tCVE:     2012-1889\n\tBUGTRAQ: <MISSING>\n\tURL:     technet.microsoft.com/en-us/security/bulletin/ms12-043\nClasstype : attempted-user\nSid       : 23304\nRev       : 4"
    connection "alert tcp $EXTERNAL_NET $FILE_DATA_PORTS -> $HOME_NET any"
    message "BROWSER-PLUGINS Microsoft Internet Explorer MSXML .definition ActiveX clsid access attempt"
    flow "to_client,established"
    detection "flowbits:set,acunetix-scan;\ncontent:\"Acunetix-\"; fast_pattern:only; http_header;"
    metadata "policy balanced-ips drop, policy security-ips drop, service ftp-data, service http, service imap, service pop3"
    class_type "attempted-user"
    state               "UNCHANGED"
    publish_status      Rule::PUBLISH_STATUS_SYNCHED
    edit_status         Rule::EDIT_STATUS_SYNCHED
    parsed              true
    on                  true
    tested              false
    committed           true
    task_id             nil
    rule_category_id    1

    factory :synched_rule do
      sid                 10127
      gid                 1
      rev                 3
      state               "UNCHANGED"
      publish_status      Rule::PUBLISH_STATUS_SYNCHED
      edit_status         Rule::EDIT_STATUS_SYNCHED
      cvs_rule_content    { rule_content }
      cvs_rule_parsed     { rule_parsed }
    end
  end
end

