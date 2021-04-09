require "rails_helper"

RSpec.describe "Peake-Bridge dispute messages channels", type: :request do

  UmbrellaSecurityInfoResponse = Struct.new(:code, :body)
  UmbrellaVolumeResponse = Struct.new(:code, :body)
  UmbrellaScanResponse = Struct.new(:code, :body)


  let(:virus_total_conviction_hash) {

    {"scan_id"=>"860a53b43369df83336dfea8bcc1604b3b49868174b4b8757f6ecce7d6c0e340-1594300951", "resource"=>"1234computer.com", "url"=>"http://1234computer.com/", "response_code"=>1, "scan_date"=>"2020-07-09 13:22:31", "permalink"=>"https://www.virustotal.com/gui/url/860a53b43369df83336dfea8bcc1604b3b49868174b4b8757f6ecce7d6c0e340/detection/u-860a53b43369df83336dfea8bcc1604b3b49868174b4b8757f6ecce7d6c0e340-1594300951", "verbose_msg"=>"Scan finished, scan information embedded in this object", "filescan_id"=>nil, "positives"=>3, "total"=>79, "scans"=>{"Botvrij.eu"=>{"detected"=>false, "result"=>"clean site"}, "Feodo Tracker"=>{"detected"=>false, "result"=>"clean site"}, "CLEAN MX"=>{"detected"=>false, "result"=>"clean site"}, "DNS8"=>{"detected"=>false, "result"=>"clean site"}, "NotMining"=>{"detected"=>false, "result"=>"unrated site"}, "VX Vault"=>{"detected"=>false, "result"=>"clean site"}, "securolytics"=>{"detected"=>false, "result"=>"clean site"}, "Tencent"=>{"detected"=>false, "result"=>"clean site"}, "MalwarePatrol"=>{"detected"=>false, "result"=>"clean site"}, "MalSilo"=>{"detected"=>false, "result"=>"clean site"}, "Comodo Valkyrie Verdict"=>{"detected"=>false, "result"=>"unrated site"}, "PhishLabs"=>{"detected"=>false, "result"=>"unrated site"}, "EmergingThreats"=>{"detected"=>false, "result"=>"clean site"}, "Sangfor"=>{"detected"=>false, "result"=>"clean site"}, "K7AntiVirus"=>{"detected"=>false, "result"=>"clean site"}, "Spam404"=>{"detected"=>false, "result"=>"clean site"}, "Virusdie External Site Scan"=>{"detected"=>false, "result"=>"clean site"}, "Artists Against 419"=>{"detected"=>false, "result"=>"clean site"}, "IPsum"=>{"detected"=>false, "result"=>"clean site"}, "Cyren"=>{"detected"=>false, "result"=>"clean site"}, "Quttera"=>{"detected"=>false, "result"=>"clean site"}, "AegisLab WebGuard"=>{"detected"=>false, "result"=>"clean site"}, "MalwareDomainList"=>{"detected"=>false, "result"=>"clean site", "detail"=>"http://www.malwaredomainlist.com/mdl.php?search=1234computer.com"}, "Lumu"=>{"detected"=>false, "result"=>"unrated site"}, "zvelo"=>{"detected"=>false, "result"=>"clean site"}, "Google Safebrowsing"=>{"detected"=>false, "result"=>"clean site"}, "Kaspersky"=>{"detected"=>true, "result"=>"phishing"}, "BitDefender"=>{"detected"=>false, "result"=>"clean site"}, "GreenSnow"=>{"detected"=>false, "result"=>"clean site"}, "G-Data"=>{"detected"=>false, "result"=>"clean site"}, "OpenPhish"=>{"detected"=>false, "result"=>"clean site"}, "Malware Domain Blocklist"=>{"detected"=>false, "result"=>"clean site"}, "AutoShun"=>{"detected"=>false, "result"=>"unrated site"}, "Trustwave"=>{"detected"=>false, "result"=>"clean site"}, "Web Security Guard"=>{"detected"=>false, "result"=>"clean site"}, "Cyan"=>{"detected"=>false, "result"=>"unrated site"}, "CyRadar"=>{"detected"=>false, "result"=>"clean site"}, "desenmascara.me"=>{"detected"=>false, "result"=>"clean site"}, "ADMINUSLabs"=>{"detected"=>false, "result"=>"clean site"}, "CINS Army"=>{"detected"=>false, "result"=>"clean site"}, "Dr.Web"=>{"detected"=>false, "result"=>"clean site"}, "AlienVault"=>{"detected"=>false, "result"=>"clean site"}, "Emsisoft"=>{"detected"=>false, "result"=>"clean site"}, "Spamhaus"=>{"detected"=>false, "result"=>"clean site"}, "malwares.com URL checker"=>{"detected"=>false, "result"=>"clean site"}, "Phishtank"=>{"detected"=>false, "result"=>"clean site"}, "EonScope"=>{"detected"=>false, "result"=>"clean site"}, "Malwared"=>{"detected"=>false, "result"=>"clean site"}, "Avira"=>{"detected"=>true, "result"=>"phishing site"}, "Cisco Talos IP Blacklist"=>{"detected"=>false, "result"=>"clean site"}, "CyberCrime"=>{"detected"=>false, "result"=>"clean site"}, "Antiy-AVL"=>{"detected"=>false, "result"=>"clean site"}, "Forcepoint ThreatSeeker"=>{"detected"=>true, "result"=>"phishing site"}, "SCUMWARE.org"=>{"detected"=>false, "result"=>"clean site"}, "Certego"=>{"detected"=>false, "result"=>"clean site"}, "Yandex Safebrowsing"=>{"detected"=>false, "result"=>"clean site", "detail"=>"http://yandex.com/infected?l10n=en&url=http://1234computer.com/"}, "ESET"=>{"detected"=>false, "result"=>"clean site"}, "Threatsourcing"=>{"detected"=>false, "result"=>"clean site"}, "URLhaus"=>{"detected"=>false, "result"=>"clean site"}, "SecureBrain"=>{"detected"=>false, "result"=>"clean site"}, "Nucleon"=>{"detected"=>false, "result"=>"clean site"}, "PREBYTES"=>{"detected"=>false, "result"=>"clean site"}, "Sophos"=>{"detected"=>false, "result"=>"unrated site"}, "Blueliv"=>{"detected"=>false, "result"=>"clean site"}, "BlockList"=>{"detected"=>false, "result"=>"clean site"}, "Netcraft"=>{"detected"=>false, "result"=>"unrated site"}, "CRDF"=>{"detected"=>false, "result"=>"clean site"}, "ThreatHive"=>{"detected"=>false, "result"=>"clean site"}, "BADWARE.INFO"=>{"detected"=>false, "result"=>"clean site"}, "FraudScore"=>{"detected"=>false, "result"=>"clean site"}, "Quick Heal"=>{"detected"=>false, "result"=>"clean site"}, "Rising"=>{"detected"=>false, "result"=>"clean site"}, "StopBadware"=>{"detected"=>false, "result"=>"unrated site"}, "Sucuri SiteCheck"=>{"detected"=>false, "result"=>"clean site"}, "Fortinet"=>{"detected"=>true, "result"=>"phishing site"}, "StopForumSpam"=>{"detected"=>false, "result"=>"clean site"}, "ZeroCERT"=>{"detected"=>false, "result"=>"clean site"}, "Baidu-International"=>{"detected"=>false, "result"=>"clean site"}, "Phishing Database"=>{"detected"=>false, "result"=>"clean site"}}}
  }

  let(:vrt_incoming) { FactoryBot.create(:vrt_incoming_user) }
  let(:guest_company) { FactoryBot.create(:guest_company) }
  let(:company_name) { 'WRMC' }
  let(:customer_name) { '3-Support Support' }
  let(:customer_email) { 'webmaster@cmim.org' }
  let(:existing_company) { FactoryBot.create(:company, name: company_name) }
  let(:existing_customer) do
    FactoryBot.create(:customer, name: customer_name, email: customer_email, company: existing_company)
  end
  let(:dispute_message_json) do
    {
        envelope: {
            channel: "ticket-event",
            addressee: "analyst-console-escalations",
            sender: "talos-intelligence"
        },
        message: {
            dispute: {
                source_type: 'Dispute',
                source_key: 1001,
                payload: {
                    investigate_urls: {
                        "355toyota.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Good",
                            "category"=>"Not in our list"
                        },
                        "thepretenders.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Good",
                            "category"=>"Entertainment"
                        }
                    },
                    investigate_ips:{},
                    problem: 'What do I need to do to improve the reputation',
                    submission_type: 'w',
                    name: customer_name,
                    user_company: company_name,
                    email: 'webmaster@cmim.org',
                    email_subject: 'Now AC is ready, 355 Toyota and The Pretenders reputation dispute.',
                    email_body: "____________________________________________________________\nUser-entered Information:\n____________________________________________________________\nTime: October 11, 2018 16:15\nName: Marlin Pierce\nE-mail: marlpier@cisco.com\nDomain: cisco.com\nInquiry Type: web\nKey Rules: \nProblem Summary: Now AC is ready, 355 Toyota and The Pretenders reputation dispute.\nIP(s) to be investigated:\n64.70.56.99\n184.168.47.225\n\nURI(s) to be investigated:\n355toyota.com\nthepretenders.com\n\nDetailed Descriptions:\n\n\n____________________________________________________________\nCisco Confidential Analysis:\n____________________________________________________________\n\nUser's IP:      ::1\n\n64.70.56.99\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       www.dealer.com\n\n184.168.47.225\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       redirect-v225.secureserver.net\n\n355toyota.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n\nthepretenders.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n",
                    user_ip: '64.70.56.99',
                    domain: '355toyota.com',
                }
            }
        }
    }
  end


  let(:dispute_message_json_bad) do
    {
        envelope: {
            channel: "ticket-event",
            addressee: "analyst-console-escalations",
            sender: "talos-intelligence"
        },
        message: {
            dispute: {
                source_type: 'Dispute',
                source_key: 1001,
                payload: {
                    investigate_urls: {
                        "355toyota.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Poor",
                            "category"=>"Not in our list"
                        }
                    },
                    investigate_ips:{},
                    problem: 'What do I need to do to improve the reputation',
                    submission_type: 'w',
                    name: customer_name,
                    user_company: company_name,
                    email: 'webmaster@cmim.org',
                    email_subject: 'Now AC is ready, 355 Toyota and The Pretenders reputation dispute.',
                    email_body: "____________________________________________________________\nUser-entered Information:\n____________________________________________________________\nTime: October 11, 2018 16:15\nName: Marlin Pierce\nE-mail: marlpier@cisco.com\nDomain: cisco.com\nInquiry Type: web\nKey Rules: \nProblem Summary: Now AC is ready, 355 Toyota and The Pretenders reputation dispute.\nIP(s) to be investigated:\n64.70.56.99\n184.168.47.225\n\nURI(s) to be investigated:\n355toyota.com\nthepretenders.com\n\nDetailed Descriptions:\n\n\n____________________________________________________________\nCisco Confidential Analysis:\n____________________________________________________________\n\nUser's IP:      ::1\n\n64.70.56.99\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       www.dealer.com\n\n184.168.47.225\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       redirect-v225.secureserver.net\n\n355toyota.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n\nthepretenders.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n",
                    user_ip: '64.70.56.99',
                    domain: '355toyota.com',
                }
            }
        }
    }
  end


  let(:mininum_auto_resolve_json_allow) do
    {
        envelope: {
            channel: "ticket-event",
            addressee: "analyst-console-escalations",
            sender: "talos-intelligence"
        },
        message: {
            dispute: {
                source_type: 'Dispute',
                source_key: 1001,
                payload: {
                    investigate_urls: {
                        "355toyota.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"wlw, wlm, wlh",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Poor",
                            "category"=>"Not in our list"
                        }
                    },
                    investigate_ips:{},
                    problem: 'What do I need to do to improve the reputation',
                    submission_type: 'w',
                    name: customer_name,
                    user_company: company_name,
                    email: 'webmaster@cmim.org',
                    email_subject: 'Now AC is ready, 355 Toyota and The Pretenders reputation dispute.',
                    email_body: "____________________________________________________________\nUser-entered Information:\n____________________________________________________________\nTime: October 11, 2018 16:15\nName: Marlin Pierce\nE-mail: marlpier@cisco.com\nDomain: cisco.com\nInquiry Type: web\nKey Rules: \nProblem Summary: Now AC is ready, 355 Toyota and The Pretenders reputation dispute.\nIP(s) to be investigated:\n64.70.56.99\n184.168.47.225\n\nURI(s) to be investigated:\n355toyota.com\nthepretenders.com\n\nDetailed Descriptions:\n\n\n____________________________________________________________\nCisco Confidential Analysis:\n____________________________________________________________\n\nUser's IP:      ::1\n\n64.70.56.99\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       www.dealer.com\n\n184.168.47.225\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       redirect-v225.secureserver.net\n\n355toyota.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n\nthepretenders.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n",
                    user_ip: '64.70.56.99',
                    domain: '355toyota.com',
                }
            }
        }
    }
  end

  it 'receives dispute payload message and does not auto resolve if there are no conditions' do
    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: dispute_message_json

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(2)
    expect(dispute.dispute_entries.where(uri: '355toyota.com')).to exist
    expect(dispute.dispute_entries.where(uri: 'thepretenders.com')).to exist

    dispute_entry_1 = DisputeEntry.where(:uri => '355toyota.com').first
    dispute_entry_2 = DisputeEntry.where(:uri => 'thepretenders.com').first

    expect(dispute_entry_1.status).to eql(DisputeEntry::NEW)
    expect(dispute_entry_2.status).to eql(DisputeEntry::NEW)


  end

  it 'receives dispute payload message and auto resolves ticket' do

    @umbrella_popular_bad = UmbrellaSecurityInfoResponse.new
    @umbrella_popular_bad.code = 200
    @umbrella_popular_bad.body = "{\"dga_score\":0.0,\"perplexity\":0.1698321879522074,\"entropy\":3.4594316186372978,\"securerank2\":0.0,\"pagerank\":0.0,\"asn_score\":-0.014739406284196042,\"prefix_score\":-0.023982712069696013,\"rip_score\":-0.011198019721606252,\"popularity\":0.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.5],[\"BR\",0.5]],\"geodiversity_normalized\":[[\"BR\",0.863526213328589],[\"US\",0.13647378667141086]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"

    @umbrella_scan_bad = UmbrellaScanResponse.new
    @umbrella_scan_bad.code = 200
    @umbrella_scan_bad.body = "{\"1234computer.com\":{\"status\":-1,\"security_categories\":[\"66\"],\"content_categories\":[\"121\"]}}"

    expect(Umbrella::SecurityInfo).to receive(:query_info).with(address: "355toyota.com").and_return(@umbrella_popular_bad).at_least(:once)
    expect(Virustotal::Scan).to receive(:scan_hashes).and_return(virus_total_conviction_hash).at_least(:once)
    expect(RepApi::Whitelist).to receive(:get_whitelist_info).and_raise(RepApi::RepApiNotFoundError, "HTTP response 404").at_least(:once)

    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: dispute_message_json_bad

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    expect(dispute.dispute_entries.where(uri: '355toyota.com')).to exist


    dispute_entry_1 = DisputeEntry.where(:uri => '355toyota.com').first

    expect(dispute_entry_1.status).to eql(DisputeEntry::STATUS_RESOLVED)
    expect(dispute_entry_1.resolution).to eql(DisputeEntry::STATUS_RESOLVED_FIXED_FN)

    expect(dispute_entry_1.auto_resolve_log).to eql("--------Starting Data---------<br>suggested disposition: Poor<br>effective disposition info: \"Neutral\"<br>-----------------------------<br>Umbrella popularity rating: 0.0: result of pass: false<br><br>no sds rulehits detected against allow list<br><br>no entry with reptool whitelist, continuing.<br><br>vt results: Kaspersky,Avira,Forcepoint ThreatSeeker,Fortinet\n<br><br>trusted vt hits: 2\n")


  end

  it 'receives dispute payload message and does not auto resolve if rulehits are allow list types' do

    @umbrella_popular_bad = UmbrellaSecurityInfoResponse.new
    @umbrella_popular_bad.code = 200
    @umbrella_popular_bad.body = "{\"dga_score\":0.0,\"perplexity\":0.1698321879522074,\"entropy\":3.4594316186372978,\"securerank2\":0.0,\"pagerank\":0.0,\"asn_score\":-0.014739406284196042,\"prefix_score\":-0.023982712069696013,\"rip_score\":-0.011198019721606252,\"popularity\":0.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.5],[\"BR\",0.5]],\"geodiversity_normalized\":[[\"BR\",0.863526213328589],[\"US\",0.13647378667141086]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"


    expect(Umbrella::SecurityInfo).to receive(:query_info).with(address: "355toyota.com").and_return(@umbrella_popular_bad).at_least(:once)
    #expect(Virustotal::Scan).to receive(:scan_hashes).and_return(virus_total_conviction_hash).at_least(:once)
    #expect(RepApi::Whitelist).to receive(:get_whitelist_info).and_raise(RepApi::RepApiNotFoundError, "HTTP response 404").at_least(:once)

    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: mininum_auto_resolve_json_allow

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    expect(dispute.dispute_entries.where(uri: '355toyota.com')).to exist


    dispute_entry_1 = DisputeEntry.where(:uri => '355toyota.com').first

    expect(dispute_entry_1.status).to eql(DisputeEntry::NEW)
    expect(dispute_entry_1.resolution).to eql("")
    expect(dispute_entry_1.auto_resolve_log).to eql("--------Starting Data---------<br>suggested disposition: Poor<br>effective disposition info: \"Neutral\"<br>-----------------------------<br>Umbrella popularity rating: 0.0: result of pass: false<br><br>allow list hits from SDS detected: wlw,wlm,wlh")


  end

  it 'receives dispute payload message and does not auto resolve if config is off' do

    @umbrella_popular_bad = UmbrellaSecurityInfoResponse.new
    @umbrella_popular_bad.code = 200
    @umbrella_popular_bad.body = "{\"dga_score\":0.0,\"perplexity\":0.1698321879522074,\"entropy\":3.4594316186372978,\"securerank2\":0.0,\"pagerank\":0.0,\"asn_score\":-0.014739406284196042,\"prefix_score\":-0.023982712069696013,\"rip_score\":-0.011198019721606252,\"popularity\":0.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.5],[\"BR\",0.5]],\"geodiversity_normalized\":[[\"BR\",0.863526213328589],[\"US\",0.13647378667141086]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"

    @umbrella_scan_bad = UmbrellaScanResponse.new
    @umbrella_scan_bad.code = 200
    @umbrella_scan_bad.body = "{\"1234computer.com\":{\"status\":-1,\"security_categories\":[\"66\"],\"content_categories\":[\"121\"]}}"

    expect(AutoResolve).to receive(:auto_resolve_toggle).and_return(false).at_least(:once)

    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: dispute_message_json_bad

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    expect(dispute.dispute_entries.where(uri: '355toyota.com')).to exist


    dispute_entry_1 = DisputeEntry.where(:uri => '355toyota.com').first

    expect(dispute_entry_1.status).to eql(DisputeEntry::NEW)
    expect(dispute_entry_1.resolution).to eql("")
    expect(dispute_entry_1.auto_resolve_log).to eql("--------Starting Data---------<br>suggested disposition: Poor<br>effective disposition info: \"Neutral\"<br>-----------------------------<br>auto resolution is turned off or is experiencing configuration error")

  end

end
