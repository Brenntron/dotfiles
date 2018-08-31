FactoryBot.define do
  factory :rule do
    gid                 {1}
    sequence(:sid)      {|n| 19500 + n }
    rev                 {3}
    message {"BROWSER-PLUGINS Microsoft Internet Explorer MSXML .definition ActiveX clsid access attempt"}
    connection {"alert tcp $EXTERNAL_NET $FILE_DATA_PORTS -> $HOME_NET any"}
    flow {"to_client,established"}
    detection {"flowbits:set,acunetix-scan; content:\"Acunetix-\"; fast_pattern:only; http_header;"}
    metadata {"policy balanced-ips drop, policy security-ips drop, service ftp-data, service http, service imap, service pop3"}
    class_type {"attempted-user"}
    rule_content { %Q~alert tcp $EXTERNAL_NET $FILE_DATA_PORTS -> $HOME_NET any (msg:"#{message}"; flow:to_client,established; #{detection}; #{metadata}; reference:cve,2012-1889; reference:url,technet.microsoft.com/en-us/security/bulletin/ms12-043; classtype:attempted-user; sid:#{sid}; rev:#{rev};)~ }
    rule_parsed {"Connection: alert tcp $EXTERNAL_NET $FILE_DATA_PORTS -> $HOME_NET any\nMessage   : BROWSER-PLUGINS Microsoft Internet Explorer MSXML .definition ActiveX clsid access attempt\nFlow      : to_client,established\nDetection :\n\tfile_data;\n\tcontent:\"Msxml2.FreeThreadedDOMDocument.6.0\"; fast_pattern:only;\n\tcontent:\".definition(\"; nocase;\n\tpcre:\"/(var|set)\\s+\\w+\\s*=\\s*(new\\s+ActiveXObject|CreateObject)\\s*\\((?P<q1>(\\x22|\\x27|))Msxml2\\.FreeThreadedDOMDocument\\.6\\.0(?P=q1)\\)/smi\";\nMetadata  :\n\tPolicy: balanced-ips drop, security-ips drop\n\tService: ftp-data, imap, pop3, http\nReferences:\n\tCVE:     2012-1889\n\tBUGTRAQ: <MISSING>\n\tURL:     technet.microsoft.com/en-us/security/bulletin/ms12-043\nClasstype : attempted-user\nSid       : 23304\nRev       : 4"}
    state                               { "UNCHANGED" }
    publish_status                      { Rule::PUBLISH_STATUS_SYNCHED }
    edit_status                         { Rule::EDIT_STATUS_SYNCHED }
    parsed                              {nil}
    on                                  {true}
    committed                           {true}
    task_id                             {nil}
    rule_category_id                    {1}

    factory :synched_rule do
      state                             { Rule::UNCHANGED_STATE }
      publish_status                    { Rule::PUBLISH_STATUS_SYNCHED }
      edit_status                       { Rule::EDIT_STATUS_SYNCHED }
      doc_status                        { Rule::DOC_STATUS_SYNCHED }
      parsed                            {true}
      cvs_rule_content    { rule_content }
      cvs_rule_parsed     { rule_parsed }
    end

    factory :edited_rule do
      state                             { Rule::UPDATED_STATE }
      publish_status                    { Rule::PUBLISH_STATUS_CURRENT_EDIT }
      edit_status                       { Rule::EDIT_STATUS_EDIT }
      doc_status                        { Rule::DOC_STATUS_UPDATED }
      cvs_rule_content    { "alert tcp $EXTERNAL_NET $FILE_DATA_PORTS -> $HOME_NET any (msg:\"BROWSER-PLUGINS ActiveX clsid access attempt\"; sid:#{sid}; rev:#{rev};)" }
      cvs_rule_parsed     { "Connection: alert tcp $EXTERNAL_NET $FILE_DATA_PORTS -> $HOME_NET any" }

      before(:create) do |rule, evaluator|
        parsed = rule.parsed
        rule_content =
            if rule.rule_content
              rule.rule_content
            else
              rule_grep_line = Rule.grep_line_from_file(rule.sid, rule.gid)
              filename, line_number, rule_content_out = rule_grep_line.partition(/:\d+:/)
              rule_content_out
            end
        parser = RuleSyntax::RuleParser.new(rule_content)
        rule.assign_from_visrule(rule_content)
        rule.assign_from_parser(parser.attributes)
        rule.update(rule_content: rule.rule_content.gsub('->', '<->'))
        rule.update(parsed: parsed) unless parsed.nil?
      end
    end

    factory :stale_rule do
      state                             { Rule::STALE_STATE }
      publish_status                    { Rule::PUBLISH_STATUS_STALE_EDIT }
      edit_status                       { Rule::EDIT_STATUS_EDIT }
      doc_status                        { Rule::DOC_STATUS_UPDATED }
      cvs_rule_content    { "alert tcp $EXTERNAL_NET $FILE_DATA_PORTS -> $HOME_NET any (msg:\"BROWSER-PLUGINS ActiveX clsid access attempt\"; sid:#{sid}; rev:#{rev};)" }
      cvs_rule_parsed     { "Connection: alert tcp $EXTERNAL_NET $FILE_DATA_PORTS -> $HOME_NET any" }

      before(:create) do |rule, evaluator|
        rule_grep_line = Rule.grep_line_from_file(rule.sid, rule.gid)
        filename, line_number, rule_content = rule_grep_line.partition(/:\d+:/)
        parser = RuleSyntax::RuleParser.new(rule_content)
        rule.assign_from_user_edit(rule_content, parser: parser)
        rule.update(rule_content: rule.rule_content.gsub('->', '<->'))
      end
    end
  end
end

