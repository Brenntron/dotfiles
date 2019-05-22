describe Dispute do
  let(:target_url_address) {'www.spanx.com'}
  let(:target_ip_address) {'184.168.221.74'}
  let(:dispute_email) do
    <<~HEREDOC
        ____________________________________________________________
        User-entered Information:
        ____________________________________________________________
        Time: September 03, 2018 12:04\nName: Marlin Pierce\nE-mail: marlpier@cisco.com
        Domain: cisco.com
        Inquiry Type: web
        Key Rules: 
        Problem Summary: New category
        IP(s) to be investigated:


        URI(s) to be investigated:
        www.spanx.com
        
        Detailed
        Descriptions:
        
        
        ____________________________________________________________
        Cisco Confidential Analysis:
        ____________________________________________________________
        
        User's IP:      ::1
        
        www.spanx.com
        WBRS Score:     1.58
        WBRS Rule Hits: alx_cln, vsvd
        Hostname's IPs:
    HEREDOC
  end
  let(:fn_ip_dispute_message_payload) do
    ActionController::Parameters.new(
        {
            payload: {
                'name' => "Marlin Pierce",
                'email' => "marlpier@cisco.com",
                'domain' => target_ip_address,
                'problem' => "New category",
                'details' => '',
                'user_ip' => "::1",
                'ticket_time' => "September 03, 2018 12:04",
                'investigate_ips' => {
                    target_ip_address => {
                        "wbrs" => {
                            'WBRS_SCORE' => '1.58',
                            'WBRS_Rule_Hits' => "alx_cln, vsvd",
                            'Hostname_ips' => '',
                            'rep_sugg' => "Good",
                            'category' => "Shopping"
                        },
                        "sbrs" => {
                            "SBRS_SCORE"=>"No score",
                            "SBRS_Rule_Hits"=>"",
                            "Hostname"=>"www.pretenders.com",
                            'rep_sugg' => "Good",
                            "category"=>"Search Engines and Portals"
                        },
                    }
                },
                'investigate_urls' => {},
                'email_subject' => "New category",
                'email_body' => dispute_email,
                'user_company' => "Cisco Systems, Inc.",
                'submission_type' => "w"
            },
            source_key: 47,
            source_type: "Dispute"
    })
  end
  let(:fp_ip_dispute_message_payload) do
    ActionController::Parameters.new(
        {
            payload: {
                'name' => "Marlin Pierce",
                'email' => "marlpier@cisco.com",
                'domain' => target_ip_address,
                'problem' => "New category",
                'details' => '',
                'user_ip' => "::1",
                'ticket_time' => "September 03, 2018 12:04",
                'investigate_ips' => {
                    target_ip_address => {
                        "wbrs" => {
                            'WBRS_SCORE' => '1.58',
                            'WBRS_Rule_Hits' => "alx_cln, vsvd",
                            'Hostname_ips' => '',
                            'rep_sugg' => "High risk",
                            'category' => "Shopping"
                        },
                        "sbrs" => {
                            "SBRS_SCORE"=>"No score",
                            "SBRS_Rule_Hits"=>"",
                            "Hostname"=>"www.pretenders.com",
                            'rep_sugg' => "High risk",
                            "category"=>"Search Engines and Portals"
                        },
                    }
                },
                'investigate_urls' => {},
                'email_subject' => "New category",
                'email_body' => dispute_email,
                'user_company' => "Cisco Systems, Inc.",
                'submission_type' => "w"
            },
            source_key: 47,
            source_type: "Dispute"
    })
  end
  let(:fn_url_dispute_message_payload) do
    ActionController::Parameters.new(
        {
            payload: {
                'name' => "Marlin Pierce",
                'email' => "marlpier@cisco.com",
                'domain' => target_url_address,
                'problem' => "New category",
                'details' => '',
                'user_ip' => "::1",
                'ticket_time' => "September 03, 2018 12:04",
                'investigate_ips' => {},
                'investigate_urls' => {
                    target_url_address => {
                        'WBRS_SCORE' => '1.58',
                        'WBRS_Rule_Hits' => "alx_cln, vsvd",
                        'Hostname_ips' => '',
                        'rep_sugg' => "Good",
                        'category' => "Shopping"

                    }
                },
                'email_subject' => "New category",
                'email_body' => dispute_email,
                'user_company' => "Cisco Systems, Inc.",
                'submission_type' => "w"
            },
            source_key: 47,
            source_type: "Dispute"
    })
  end
  let(:fp_url_dispute_message_payload) do
    ActionController::Parameters.new(
        {
            payload: {
                'name' => "Marlin Pierce",
                'email' => "marlpier@cisco.com",
                'domain' => target_url_address,
                'problem' => "New category",
                'details' => '',
                'user_ip' => "::1",
                'ticket_time' => "September 03, 2018 12:04",
                'investigate_ips' => {},
                'investigate_urls' => {
                    target_url_address => {
                        'WBRS_SCORE' => '1.58',
                        'WBRS_Rule_Hits' => "alx_cln, vsvd",
                        'Hostname_ips' => '',
                        'rep_sugg' => "High risk",
                        'category' => "Shopping"

                    }
                },
                'email_subject' => "New category",
                'email_body' => dispute_email,
                'user_company' => "Cisco Systems, Inc.",
                'submission_type' => "w"
            },
            source_key: 47,
            source_type: "Dispute"
    })
  end
  let(:top_url_response_json) do
    {
        target_url_address => true,
        target_ip_address => true,
    }.to_json
  end
  let(:blacklist_json) do
    {
        target_url_address => 'NOT_FOUND',
        target_ip_address => 'NOT_FOUND',
    }.to_json
  end
  let(:virustotal_json) do
    {
        "scan_id": "263a0bca315778e09734a8ac9539f557905e909847d901946c5df1a13e631b17-1536170044",
        "resource": target_url_address,
        "url": "http://#{target_url_address}/",
        "response_code": 1,
        "scan_date": "2018-09-05 17:54:04",
        "permalink": "https://www.virustotal.com/url/263a0bca315778e09734a8ac9539f557905e909847d901946c5df1a13e631b17/analysis/1536170044/", "verbose_msg": "Scan finished, scan information embedded in this object",
        "filescan_id": nil,
        "positives": 0,
        "total": 67,
        "scans": {
            "CLEAN MX": {"detected": false, "result": "clean site"},
            "DNS8": {"detected": false, "result": "clean site"},
            "OpenPhish": {"detected": false, "result": "clean site"},
            "VX Vault": {"detected": false, "result": "clean site"},
            "ZDB Zeus": {"detected": false, "result": "clean site"},
            "ZCloudsec": {"detected": false, "result": "clean site"},
            "PhishLabs": {"detected": false, "result": "unrated site"},
            "Zerofox": {"detected": false, "result": "clean site"},
            "K7AntiVirus": {"detected": false, "result": "clean site"},
            "FraudSense": {"detected": false, "result": "clean site"},
            "Virusdie External Site Scan": {"detected": false, "result": "clean site"},
            "Quttera": {"detected": false, "result": "clean site"},
            "AegisLab WebGuard": {"detected": false, "result": "clean site"},
            "MalwareDomainList": {"detected": false, "result": "clean site", "detail": "http://www.malwaredomainlist.com/mdl.php?search=#{target_url_address}"},
            "ZeusTracker": {"detected": false, "result": "clean site", "detail": "https://zeustracker.abuse.ch/monitor.php?host=#{target_url_address}"},
            "zvelo": {"detected": false, "result": "clean site"},
            "Google Safebrowsing": {"detected": false, "result": "clean site"},
            "Kaspersky": {"detected": false, "result": "clean site"},
            "BitDefender": {"detected": false, "result": "clean site"},
            "Opera": {"detected": false, "result": "clean site"},
            "Certly": {"detected": false, "result": "clean site"},
            "G-Data": {"detected": false, "result": "clean site"},
            "C-SIRT": {"detected": false, "result": "clean site"},
            "CyberCrime": {"detected": false, "result": "clean site"},
            "SecureBrain": {"detected": false, "result": "clean site"},
            "Malware Domain Blocklist": {"detected": false, "result": "clean site"},
            "MalwarePatrol": {"detected": false, "result": "clean site"},
            "Webutation": {"detected": false, "result": "clean site"},
            "Trustwave": {"detected": false, "result": "clean site"},
            "Web Security Guard": {"detected": false, "result": "clean site"},
            "CyRadar": {"detected": false, "result": "clean site"},
            "desenmascara.me": {"detected": false, "result": "clean site"},
            "ADMINUSLabs": {"detected": false, "result": "clean site"},
            "Malwarebytes hpHosts": {"detected": false, "result": "clean site"},
            "Dr.Web": {"detected": false, "result": "clean site"},
            "AlienVault": {"detected": false, "result": "clean site"},
            "Emsisoft": {"detected": false, "result": "clean site"},
            "Rising": {"detected": false, "result": "clean site"},
            "Malc0de Database": {"detected": false, "result": "clean site", "detail": "http://malc0de.com/database/index.php?search=#{target_url_address}"},
            "malwares.com URL checker": {"detected": false, "result": "clean site"},
            "Phishtank": {"detected": false, "result": "clean site"},
            "Malwared": {"detected": false, "result": "clean site"},
            "Avira": {"detected": false, "result": "clean site"},
            "NotMining": {"detected": false, "result": "unrated site"},
            "StopBadware": {"detected": false, "result": "unrated site"},
            "Antiy-AVL": {"detected": false, "result": "clean site"},
            "Forcepoint ThreatSeeker": {"detected": false, "result": "clean site"},
            "SCUMWARE.org": {"detected": false, "result": "clean site"},
            "Comodo Site Inspector": {"detected": false, "result": "clean site"},
            "Malekal": {"detected": false, "result": "clean site"},
            "ESET": {"detected": false, "result": "clean site"},
            "Sophos": {"detected": false, "result": "unrated site"},
            "Yandex Safebrowsing": {"detected": false, "result": "clean site", "detail": "http://yandex.com/infected?l10n=en&url=http://#{target_url_address}/"},
            "Spam404": {"detected": false, "result": "clean site"},
            "Nucleon": {"detected": false, "result": "clean site"},
            "Sucuri SiteCheck": {"detected": false, "result": "clean site"},
            "Blueliv": {"detected": false, "result": "clean site"},
            "Netcraft": {"detected": false, "result": "unrated site"},
            "AutoShun": {"detected": false, "result": "unrated site"},
            "ThreatHive": {"detected": false, "result": "clean site"},
            "FraudScore": {"detected": false, "result": "clean site"},
            "Tencent": {"detected": false, "result": "clean site"},
            "URLQuery": {"detected": false, "result": "unrated site"},
            "Fortinet": {"detected": false, "result": "clean site"},
            "ZeroCERT": {"detected": false, "result": "clean site"},
            "Baidu-International": {"detected": false, "result": "clean site"},
            "securolytics": {"detected": false, "result": "clean site"}
        }
    }.to_json
  end
  let(:umbrella_clear_json) {
    {
        target_url_address => {
            "status" => 1,
            "security_categories" => [],
            "content_categories" => ["25","32"]
        }
    }.to_json
  }
  let(:manual_wlbl_json) do
    {
        "data" => [
            {
                "ctime" => "Wed, 15 Aug 2018 19:21:06 GMT",
                "id" => 100137,
                "list_type" => "BL-weak",
                "mtime" => "Wed, 15 Aug 2018 19:21:06 GMT",
                "threat_cats" => [5, 6],
                "url" => "webmail-191-252-36-28.globo.com",
                "username" => "aivaniuk",
                "state" => "active"
            }
        ],
        "meta" => {
            "limit" => 5,
            "rows_found" => 1
        }
    }.to_json
  end
  let(:xbrs_domain_json) do
    "---\n" +
    {
        "api" => {
            "memory_footprint_kb" => 55012,
            "system_top_genid" => 20573168,
            "response_took" => 0.014037847518920898,
            "response_repdb_time" => 1536348248,
            "isolation_level" => "REPEATABLE-READ",
            "request" => "http://prod-xbrs-writer1.vega.ironport.com:80/v1/domain/#{target_url_address}?consumer=TEST",
            "product_version" => "1.3.0 2018-05-16 09:38 PDT",
            "response_local_time" => 1536348248,
            "total_data_rows" => 0,
            "response_action" => "domain.one",
            "data_documents" => 1,
            "request_local_time" => 1536348248.6497071,
            "api_version" => "v1"
        },
        "resource" => {
            "requested_subdomain" => nil,
            "data_rows" => 0,
            "requested_domain" => target_url_address
        }
    }.to_json +
    "\n---\n" +
    {
        "rule_type" => "PREFIX",
        "data" => [],
        "legend" => [
            "rule_id",
            "mnemonic",
            "row_id",
            "ctime",
            "genid",
            "proto",
            "userpass",
            "subdomain",
            "domain",
            "port",
            "path",
            "query",
            "fragment",
            "attr",
            "attr_truncated",
            "path_truncated",
            "query_truncated",
            "unique_hash",
            "mtime",
            "operation"
        ]
    }.to_json
  end
  let(:umbrella_data) do
    {
        target_url_address => {
            "status" => 0,
            "security_categories" => [],
            "content_categories" => ["8", "41"]
        }
    }
  end
  let(:top_url_response_response) { double('HTTPI::Response', code: 200, body: top_url_response_json) }
  let(:blacklist_response) { double('HTTPI::Response', code: 200, body: blacklist_json) }
  let(:virustotal_response) { double('HTTPI::Response', code: 200, body: virustotal_json) }
  let(:umbrella_clear_response) { double('HTTPI::Response', code: 200, body: umbrella_clear_json) }
  let(:manual_wlbl_response) { double('HTTPI::Response', code: 200, body: manual_wlbl_json) }
  let(:xbrs_domain_response) { double('HTTPI::Response', code: 200, body: xbrs_domain_json) }
  let(:auto_resolve_new) { double('AutoResolve', resolved?: false, malicious?: nil) }
  let(:auto_convict) { double('AutoResolve', resolved?: true, malicious?: true) }
  let(:auto_acquit) { double('AutoResolve', resolved?: true, malicious?: false) }
  let(:bug_factory) do
    double('Bugzilla::Bug', create: { "id" => 101 })
  end

  before(:example) do
    FactoryBot.create(:vrt_incoming_user)
    FactoryBot.create(:guest_company)
  end

  it 'processes fn ip bridge payload' do
    allow(Wbrs::Base)
        .to receive(:call_json_request)
                .with(:post, '/v1/cat/urls/top', body: anything)
                .and_return(top_url_response_response)
    allow(RepApi::Base)
        .to receive(:call_json_request)
                .with(:post, '/blacklist/get', body: anything)
                .and_return(blacklist_response)
    allow(Virustotal::Base)
        .to receive(:call_request)
                .with(:get, anything) # TODO .with(:get, "/vtapi/v2/url/report?resource=#{target_ip_address}")
                .and_return(virustotal_response)
    allow(Umbrella::Scan)
        .to receive(:scan_result)
                .with(address: target_ip_address)
                .and_return(umbrella_clear_response)
    allow(Wbrs::Base)
        .to receive(:post_request)
                .with(path: '/v1/rep/wlbl/get', body: anything)
                .and_return(manual_wlbl_response)
    allow(Xbrs::Base)
        .to receive(:call_request)
                .with(:get, anything)
                .and_return(xbrs_domain_response)
    allow(Bridge::DisputeCreatedEvent).to receive(:new).and_return(double('Bridge::DisputeCreatedEvent', post: nil))
    bugzilla_rest_session = BugzillaRest::Session.default_session
    expect(bugzilla_rest_session).to receive(:create_bug).and_return(bugzilla_rest_session.build_bug(id: 1001))
    fn_ip_dispute_message_payload[:bugzilla_rest_session] = bugzilla_rest_session

    dispute = nil
    expect do
      dispute = Dispute.process_bridge_payload(fn_ip_dispute_message_payload)
    end.to change { Dispute.count }.from(0).to(1)

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    dispute_entry = dispute.dispute_entries.first
    expect(dispute_entry.status).to eql(DisputeEntry::NEW)
    expect(dispute_entry.resolution).to be_nil
  end

  it 'processes fp ip auto-resolve as new bridge payload' do
    allow(RepApi::Base)
        .to receive(:call_json_request)
                .with(:post, '/blacklist/get', body: anything)
                .and_return(blacklist_response)
    # TODO remove redundant API call
    allow(Wbrs::Base)
        .to receive(:call_json_request)
                .with(:post, '/v1/cat/urls/top', body: anything)
                .and_return(top_url_response_response)
    # TODO remove redundant API call
    allow(Virustotal::Base)
        .to receive(:call_request)
                .with(:get, anything) # TODO .with(:get, "/vtapi/v2/url/report?resource=#{target_ip_address}")
                .and_return(virustotal_response)
    # TODO remove redundant API call
    allow(Umbrella::Scan)
        .to receive(:scan_result)
                .with(address: target_ip_address)
                .and_return(umbrella_clear_response)
    allow(AutoResolve)
        .to receive(:create_from_payload)
                .with('IP', target_ip_address, anything, anything)
                .and_return(auto_resolve_new)
    allow(Wbrs::Base)
        .to receive(:post_request)
                .with(path: '/v1/rep/wlbl/get', body: anything)
                .and_return(manual_wlbl_response)
    allow(Xbrs::Base)
        .to receive(:call_request)
                .with(:get, anything)
                .and_return(xbrs_domain_response)
    allow(Bridge::DisputeCreatedEvent).to receive(:new).and_return(double('Bridge::DisputeCreatedEvent', post: nil))
    bugzilla_rest_session = BugzillaRest::Session.default_session
    expect(bugzilla_rest_session).to receive(:create_bug).and_return(bugzilla_rest_session.build_bug(id: 1001))
    fp_ip_dispute_message_payload[:bugzilla_rest_session] = bugzilla_rest_session

    dispute = nil
    expect do
      dispute = Dispute.process_bridge_payload(fp_ip_dispute_message_payload)
    end.to change { Dispute.count }.from(0).to(1)

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    dispute_entry = dispute.dispute_entries.first
    expect(dispute_entry.status).to eql(DisputeEntry::NEW)
    expect(dispute_entry.resolution).to be_nil
  end

  it 'processes fp ip auto-convicted bridge payload' do
    allow(RepApi::Base)
        .to receive(:call_json_request)
                .with(:post, '/blacklist/get', body: anything)
                .and_return(blacklist_response)
    # TODO remove redundant API call
    allow(Wbrs::Base)
        .to receive(:call_json_request)
                .with(:post, '/v1/cat/urls/top', body: anything)
                .and_return(top_url_response_response)
    # TODO remove redundant API call
    allow(Virustotal::Base)
        .to receive(:call_request)
                .with(:get, anything) # TODO .with(:get, "/vtapi/v2/url/report?resource=#{target_ip_address}")
                .and_return(virustotal_response)
    # TODO remove redundant API call
    allow(Umbrella::Scan)
        .to receive(:scan_result)
                .with(address: target_ip_address)
                .and_return(umbrella_clear_response)
    allow(AutoResolve)
        .to receive(:create_from_payload)
                .with('IP', target_ip_address, anything, anything)
                .and_return(auto_convict)
    allow(Wbrs::Base)
        .to receive(:post_request)
                .with(path: '/v1/rep/wlbl/get', body: anything)
                .and_return(manual_wlbl_response)
    allow(Xbrs::Base)
        .to receive(:call_request)
                .with(:get, anything)
                .and_return(xbrs_domain_response)
    allow(Bridge::DisputeCreatedEvent).to receive(:new).and_return(double('Bridge::DisputeCreatedEvent', post: nil))
    bugzilla_rest_session = BugzillaRest::Session.default_session
    expect(bugzilla_rest_session).to receive(:create_bug).and_return(bugzilla_rest_session.build_bug(id: 1001))
    fp_ip_dispute_message_payload[:bugzilla_rest_session] = bugzilla_rest_session

    dispute = nil
    expect do
      dispute = Dispute.process_bridge_payload(fp_ip_dispute_message_payload)
    end.to change { Dispute.count }.from(0).to(1)

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    dispute_entry = dispute.dispute_entries.first
    expect(dispute_entry.status).to eql(DisputeEntry::STATUS_RESOLVED)
    expect(dispute_entry.resolution).to eql(DisputeEntry::STATUS_RESOLVED_FIXED_FN)
  end

  it 'processes fn url bridge payload' do
    allow(Wbrs::Base)
        .to receive(:call_json_request)
                .with(:post, '/v1/cat/urls/top', body: anything)
                .and_return(top_url_response_response)
    allow(RepApi::Base)
        .to receive(:call_json_request)
                .with(:post, '/blacklist/get', body: anything)
                .and_return(blacklist_response)
    allow(Virustotal::Base)
        .to receive(:call_request)
                .with(:get, anything) # TODO .with(:get, "/vtapi/v2/url/report?resource=#{target_url_address}")
                .and_return(virustotal_response)
    allow(Umbrella::Scan)
        .to receive(:scan_result)
                .with(address: target_url_address)
                .and_return(umbrella_clear_response)
    allow(Wbrs::Base)
        .to receive(:post_request)
                .with(path: '/v1/rep/wlbl/get', body: anything)
                .and_return(manual_wlbl_response)
    allow(Xbrs::Base)
        .to receive(:call_request)
                .with(:get, anything)
                .and_return(xbrs_domain_response)
    allow(Bridge::DisputeCreatedEvent).to receive(:new).and_return(double('Bridge::DisputeCreatedEvent', post: nil))
    bugzilla_rest_session = BugzillaRest::Session.default_session
    expect(bugzilla_rest_session).to receive(:create_bug).and_return(bugzilla_rest_session.build_bug(id: 1001))
    message_payload = fp_url_dispute_message_payload
    message_payload[:bugzilla_rest_session] = bugzilla_rest_session

    dispute = nil
    expect do
      dispute = Dispute.process_bridge_payload(message_payload)
    end.to change { Dispute.count }.from(0).to(1)

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    dispute_entry = dispute.dispute_entries.first
    expect(dispute_entry.status).to eql(DisputeEntry::NEW)
    expect(dispute_entry.resolution).to be_nil
  end

  it 'processes fp url auto-resolve as new bridge payload' do
    allow(RepApi::Base)
        .to receive(:call_json_request)
                .with(:post, '/blacklist/get', body: anything)
                .and_return(blacklist_response)
    # TODO remove redundant API call
    allow(Wbrs::Base)
        .to receive(:call_json_request)
                .with(:post, '/v1/cat/urls/top', body: anything)
                .and_return(top_url_response_response)
    # TODO remove redundant API call
    allow(Virustotal::Base)
        .to receive(:call_request)
                .with(:get, anything) # TODO .with(:get, "/vtapi/v2/url/report?resource=#{target_url_address}")
                .and_return(virustotal_response)
    # TODO remove redundant API call
    allow(Umbrella::Scan)
        .to receive(:scan_result)
                .with(address: target_url_address)
                .and_return(umbrella_clear_response)
    allow(AutoResolve)
        .to receive(:create_from_payload)
                .with('URI/DOMAIN', target_url_address, anything, anything)
                .and_return(auto_resolve_new)
    allow(Wbrs::Base)
        .to receive(:post_request)
                .with(path: '/v1/rep/wlbl/get', body: anything)
                .and_return(manual_wlbl_response)
    allow(Xbrs::Base)
        .to receive(:call_request)
                .with(:get, anything)
                .and_return(xbrs_domain_response)
    allow(Bridge::DisputeCreatedEvent).to receive(:new).and_return(double('Bridge::DisputeCreatedEvent', post: nil))
    bugzilla_rest_session = BugzillaRest::Session.default_session
    expect(bugzilla_rest_session).to receive(:create_bug).and_return(bugzilla_rest_session.build_bug(id: 1001))
    fp_url_dispute_message_payload[:bugzilla_rest_session] = bugzilla_rest_session

    dispute = nil
    expect do
      dispute = Dispute.process_bridge_payload(fp_url_dispute_message_payload)
    end.to change { Dispute.count }.from(0).to(1)

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    dispute_entry = dispute.dispute_entries.first
    expect(dispute_entry.status).to eql(DisputeEntry::NEW)
    expect(dispute_entry.resolution).to be_nil
  end

  it 'processes fp url auto-convicted bridge payload' do
    allow(RepApi::Base)
        .to receive(:call_json_request)
                .with(:post, '/blacklist/get', body: anything)
                .and_return(blacklist_response)
    # TODO remove redundant API call
    allow(Wbrs::Base)
        .to receive(:call_json_request)
                .with(:post, '/v1/cat/urls/top', body: anything)
                .and_return(top_url_response_response)
    # TODO remove redundant API call
    allow(Virustotal::Base)
        .to receive(:call_request)
                .with(:get, anything) # TODO .with(:get, "/vtapi/v2/url/report?resource=#{target_url_address}")
                .and_return(virustotal_response)
    # TODO remove redundant API call
    allow(Umbrella::Scan)
        .to receive(:scan_result)
                .with(address: target_url_address)
                .and_return(umbrella_clear_response)
    allow(AutoResolve)
        .to receive(:create_from_payload)
                .with('URI/DOMAIN', target_url_address, anything, anything)
                .and_return(auto_convict)
    allow(Wbrs::Base)
        .to receive(:post_request)
                .with(path: '/v1/rep/wlbl/get', body: anything)
                .and_return(manual_wlbl_response)
    allow(Xbrs::Base)
        .to receive(:call_request)
                .with(:get, anything)
                .and_return(xbrs_domain_response)
    allow(Bridge::DisputeCreatedEvent).to receive(:new).and_return(double('Bridge::DisputeCreatedEvent', post: nil))
    bugzilla_rest_session = BugzillaRest::Session.default_session
    expect(bugzilla_rest_session).to receive(:create_bug).and_return(bugzilla_rest_session.build_bug(id: 1001))
    fp_url_dispute_message_payload[:bugzilla_rest_session] = bugzilla_rest_session

    dispute = nil
    expect do
      dispute = Dispute.process_bridge_payload(fp_url_dispute_message_payload)
    end.to change { Dispute.count }.from(0).to(1)

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    dispute_entry = dispute.dispute_entries.first
    expect(dispute_entry.status).to eql(DisputeEntry::STATUS_RESOLVED)
    expect(dispute_entry.resolution).to eql(DisputeEntry::STATUS_RESOLVED_FIXED_FN)
  end
end
