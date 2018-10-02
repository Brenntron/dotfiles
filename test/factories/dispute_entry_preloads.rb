FactoryBot.define do
  factory :dispute_entry_preload do
    dispute_entry_id { 1 }
    xbrs_history {"[{},{\"data\":[[503,\"seclytics_det_mal\",5674207180,1533013184,20250546,16909060,32,0,\"1.2.3.4\",0,1533288478,\"full\"],[503,\"seclytics_det_mal\",1869009997,1533012945,20221240,16909060,32,0,\"1.2.3.4\",0,0,\"ADD\"]],\"legend\":[\"rule_id\",\"mnemonic\",\"row_id\",\"ctime\",\"genid\",\"ip\",\"cidr\",\"attr\",\"attr_truncated\",\"dotted\",\"exclusion\",\"mtime\",\"operation\"]}]"}
    crosslisted_urls { "{\"data\":[],\"meta\":{\"limit\":1000,\"rows_found\":0}}" }
    virustotal      { "{\"scan\":\"12333434\"}" }
    wlbl            { "{\"yahoo.com\":\"NOT_FOUND\"}" }
    wbrs_list_type  { 'BL-weak' }
    umbrella        { 'Unclassified' }
  end
end
