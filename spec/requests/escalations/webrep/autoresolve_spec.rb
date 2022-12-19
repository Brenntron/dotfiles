require "rails_helper"

RSpec.describe "Peake-Bridge dispute messages channels", type: :request do

  UmbrellaSecurityInfoResponse = Struct.new(:code, :body)
  UmbrellaVolumeResponse = Struct.new(:code, :body)
  UmbrellaScanResponse = Struct.new(:code, :body)


  let(:virus_total_conviction_hash) {

    {"scan_id"=>"860a53b43369df83336dfea8bcc1604b3b49868174b4b8757f6ecce7d6c0e340-1594300951", "resource"=>"1234computer.com", "url"=>"http://1234computer.com/", "response_code"=>1, "scan_date"=>"2020-07-09 13:22:31", "permalink"=>"https://www.virustotal.com/gui/url/860a53b43369df83336dfea8bcc1604b3b49868174b4b8757f6ecce7d6c0e340/detection/u-860a53b43369df83336dfea8bcc1604b3b49868174b4b8757f6ecce7d6c0e340-1594300951", "verbose_msg"=>"Scan finished, scan information embedded in this object", "filescan_id"=>nil, "positives"=>14, "total"=>79, "scans"=>{"Botvrij.eu"=>{"detected"=>false, "result"=>"clean site"}, "Feodo Tracker"=>{"detected"=>false, "result"=>"clean site"}, "CLEAN MX"=>{"detected"=>false, "result"=>"clean site"}, "DNS8"=>{"detected"=>false, "result"=>"clean site"}, "NotMining"=>{"detected"=>false, "result"=>"unrated site"}, "VX Vault"=>{"detected"=>false, "result"=>"clean site"}, "securolytics"=>{"detected"=>false, "result"=>"clean site"}, "Tencent"=>{"detected"=>false, "result"=>"clean site"}, "MalwarePatrol"=>{"detected"=>false, "result"=>"clean site"}, "MalSilo"=>{"detected"=>false, "result"=>"clean site"}, "Comodo Valkyrie Verdict"=>{"detected"=>false, "result"=>"unrated site"}, "PhishLabs"=>{"detected"=>false, "result"=>"unrated site"}, "EmergingThreats"=>{"detected"=>false, "result"=>"clean site"}, "Sangfor"=>{"detected"=>false, "result"=>"clean site"}, "K7AntiVirus"=>{"detected"=>false, "result"=>"clean site"}, "Spam404"=>{"detected"=>false, "result"=>"clean site"}, "Virusdie External Site Scan"=>{"detected"=>false, "result"=>"clean site"}, "Artists Against 419"=>{"detected"=>false, "result"=>"clean site"}, "IPsum"=>{"detected"=>false, "result"=>"clean site"}, "Cyren"=>{"detected"=>false, "result"=>"clean site"}, "Quttera"=>{"detected"=>false, "result"=>"clean site"}, "AegisLab WebGuard"=>{"detected"=>false, "result"=>"clean site"}, "MalwareDomainList"=>{"detected"=>false, "result"=>"clean site", "detail"=>"http://www.malwaredomainlist.com/mdl.php?search=1234computer.com"}, "Lumu"=>{"detected"=>false, "result"=>"unrated site"}, "zvelo"=>{"detected"=>false, "result"=>"clean site"}, "Google Safebrowsing"=>{"detected"=>false, "result"=>"clean site"}, "Kaspersky"=>{"detected"=>true, "result"=>"phishing"}, "BitDefender"=>{"detected"=>false, "result"=>"clean site"}, "GreenSnow"=>{"detected"=>false, "result"=>"clean site"}, "G-Data"=>{"detected"=>false, "result"=>"clean site"}, "OpenPhish"=>{"detected"=>false, "result"=>"clean site"}, "Malware Domain Blocklist"=>{"detected"=>false, "result"=>"clean site"}, "AutoShun"=>{"detected"=>false, "result"=>"unrated site"}, "Trustwave"=>{"detected"=>false, "result"=>"clean site"}, "Web Security Guard"=>{"detected"=>false, "result"=>"clean site"}, "Cyan"=>{"detected"=>false, "result"=>"unrated site"}, "CyRadar"=>{"detected"=>false, "result"=>"clean site"}, "desenmascara.me"=>{"detected"=>false, "result"=>"clean site"}, "ADMINUSLabs"=>{"detected"=>false, "result"=>"clean site"}, "CINS Army"=>{"detected"=>false, "result"=>"clean site"}, "Dr.Web"=>{"detected"=>false, "result"=>"clean site"}, "AlienVault"=>{"detected"=>false, "result"=>"clean site"}, "Emsisoft"=>{"detected"=>false, "result"=>"clean site"}, "Spamhaus"=>{"detected"=>false, "result"=>"clean site"}, "malwares.com URL checker"=>{"detected"=>false, "result"=>"clean site"}, "Phishtank"=>{"detected"=>false, "result"=>"clean site"}, "EonScope"=>{"detected"=>false, "result"=>"clean site"}, "Malwared"=>{"detected"=>false, "result"=>"clean site"}, "Avira"=>{"detected"=>true, "result"=>"phishing site"}, "Cisco Talos IP Blacklist"=>{"detected"=>false, "result"=>"clean site"}, "CyberCrime"=>{"detected"=>false, "result"=>"clean site"}, "Antiy-AVL"=>{"detected"=>false, "result"=>"clean site"}, "Forcepoint ThreatSeeker"=>{"detected"=>true, "result"=>"phishing site"}, "SCUMWARE.org"=>{"detected"=>false, "result"=>"clean site"}, "Certego"=>{"detected"=>false, "result"=>"clean site"}, "Yandex Safebrowsing"=>{"detected"=>false, "result"=>"clean site", "detail"=>"http://yandex.com/infected?l10n=en&url=http://1234computer.com/"}, "ESET"=>{"detected"=>false, "result"=>"clean site"}, "Threatsourcing"=>{"detected"=>false, "result"=>"clean site"}, "URLhaus"=>{"detected"=>false, "result"=>"clean site"}, "SecureBrain"=>{"detected"=>false, "result"=>"clean site"}, "Nucleon"=>{"detected"=>false, "result"=>"clean site"}, "PREBYTES"=>{"detected"=>false, "result"=>"clean site"}, "Sophos"=>{"detected"=>false, "result"=>"unrated site"}, "Blueliv"=>{"detected"=>false, "result"=>"clean site"}, "BlockList"=>{"detected"=>false, "result"=>"clean site"}, "Netcraft"=>{"detected"=>false, "result"=>"unrated site"}, "CRDF"=>{"detected"=>false, "result"=>"clean site"}, "ThreatHive"=>{"detected"=>false, "result"=>"clean site"}, "BADWARE.INFO"=>{"detected"=>false, "result"=>"clean site"}, "FraudScore"=>{"detected"=>false, "result"=>"clean site"}, "Quick Heal"=>{"detected"=>false, "result"=>"clean site"}, "Rising"=>{"detected"=>false, "result"=>"clean site"}, "StopBadware"=>{"detected"=>false, "result"=>"unrated site"}, "Sucuri SiteCheck"=>{"detected"=>false, "result"=>"clean site"}, "Fortinet"=>{"detected"=>true, "result"=>"phishing site"}, "StopForumSpam"=>{"detected"=>false, "result"=>"clean site"}, "ZeroCERT"=>{"detected"=>false, "result"=>"clean site"}, "Baidu-International"=>{"detected"=>false, "result"=>"clean site"}, "Phishing Database"=>{"detected"=>false, "result"=>"clean site"}}}
  }

  let(:virus_total_nonconviction_hash) {

    {"scan_id"=>"860a53b43369df83336dfea8bcc1604b3b49868174b4b8757f6ecce7d6c0e340-1594300951", "resource"=>"1234computer.com", "url"=>"http://1234computer.com/", "response_code"=>1, "scan_date"=>"2020-07-09 13:22:31", "permalink"=>"https://www.virustotal.com/gui/url/860a53b43369df83336dfea8bcc1604b3b49868174b4b8757f6ecce7d6c0e340/detection/u-860a53b43369df83336dfea8bcc1604b3b49868174b4b8757f6ecce7d6c0e340-1594300951", "verbose_msg"=>"Scan finished, scan information embedded in this object", "filescan_id"=>nil, "positives"=>1, "total"=>79, "scans"=>{"Botvrij.eu"=>{"detected"=>false, "result"=>"clean site"}, "Feodo Tracker"=>{"detected"=>false, "result"=>"clean site"}, "CLEAN MX"=>{"detected"=>false, "result"=>"clean site"}, "DNS8"=>{"detected"=>false, "result"=>"clean site"}, "NotMining"=>{"detected"=>false, "result"=>"unrated site"}, "VX Vault"=>{"detected"=>false, "result"=>"clean site"}, "securolytics"=>{"detected"=>false, "result"=>"clean site"}, "Tencent"=>{"detected"=>false, "result"=>"clean site"}, "MalwarePatrol"=>{"detected"=>false, "result"=>"clean site"}, "MalSilo"=>{"detected"=>false, "result"=>"clean site"}, "Comodo Valkyrie Verdict"=>{"detected"=>false, "result"=>"unrated site"}, "PhishLabs"=>{"detected"=>false, "result"=>"unrated site"}, "EmergingThreats"=>{"detected"=>false, "result"=>"clean site"}, "Sangfor"=>{"detected"=>false, "result"=>"clean site"}, "K7AntiVirus"=>{"detected"=>false, "result"=>"clean site"}, "Spam404"=>{"detected"=>false, "result"=>"clean site"}, "Virusdie External Site Scan"=>{"detected"=>false, "result"=>"clean site"}, "Artists Against 419"=>{"detected"=>false, "result"=>"clean site"}, "IPsum"=>{"detected"=>false, "result"=>"clean site"}, "Cyren"=>{"detected"=>false, "result"=>"clean site"}, "Quttera"=>{"detected"=>false, "result"=>"clean site"}, "AegisLab WebGuard"=>{"detected"=>false, "result"=>"clean site"}, "MalwareDomainList"=>{"detected"=>false, "result"=>"clean site", "detail"=>"http://www.malwaredomainlist.com/mdl.php?search=1234computer.com"}, "Lumu"=>{"detected"=>false, "result"=>"unrated site"}, "zvelo"=>{"detected"=>false, "result"=>"clean site"}, "Google Safebrowsing"=>{"detected"=>false, "result"=>"clean site"}, "Kaspersky"=>{"detected"=>false, "result"=>"phishing"}, "BitDefender"=>{"detected"=>false, "result"=>"clean site"}, "GreenSnow"=>{"detected"=>false, "result"=>"clean site"}, "G-Data"=>{"detected"=>false, "result"=>"clean site"}, "OpenPhish"=>{"detected"=>false, "result"=>"clean site"}, "Malware Domain Blocklist"=>{"detected"=>false, "result"=>"clean site"}, "AutoShun"=>{"detected"=>false, "result"=>"unrated site"}, "Trustwave"=>{"detected"=>false, "result"=>"clean site"}, "Web Security Guard"=>{"detected"=>false, "result"=>"clean site"}, "Cyan"=>{"detected"=>false, "result"=>"unrated site"}, "CyRadar"=>{"detected"=>false, "result"=>"clean site"}, "desenmascara.me"=>{"detected"=>false, "result"=>"clean site"}, "ADMINUSLabs"=>{"detected"=>false, "result"=>"clean site"}, "CINS Army"=>{"detected"=>false, "result"=>"clean site"}, "Dr.Web"=>{"detected"=>false, "result"=>"clean site"}, "AlienVault"=>{"detected"=>false, "result"=>"clean site"}, "Emsisoft"=>{"detected"=>false, "result"=>"clean site"}, "Spamhaus"=>{"detected"=>false, "result"=>"clean site"}, "malwares.com URL checker"=>{"detected"=>false, "result"=>"clean site"}, "Phishtank"=>{"detected"=>false, "result"=>"clean site"}, "EonScope"=>{"detected"=>false, "result"=>"clean site"}, "Malwared"=>{"detected"=>false, "result"=>"clean site"}, "Avira"=>{"detected"=>false, "result"=>"phishing site"}, "Cisco Talos IP Blacklist"=>{"detected"=>false, "result"=>"clean site"}, "CyberCrime"=>{"detected"=>false, "result"=>"clean site"}, "Antiy-AVL"=>{"detected"=>false, "result"=>"clean site"}, "Forcepoint ThreatSeeker"=>{"detected"=>false, "result"=>"phishing site"}, "SCUMWARE.org"=>{"detected"=>false, "result"=>"clean site"}, "Certego"=>{"detected"=>false, "result"=>"clean site"}, "Yandex Safebrowsing"=>{"detected"=>false, "result"=>"clean site", "detail"=>"http://yandex.com/infected?l10n=en&url=http://1234computer.com/"}, "ESET"=>{"detected"=>false, "result"=>"clean site"}, "Threatsourcing"=>{"detected"=>false, "result"=>"clean site"}, "URLhaus"=>{"detected"=>false, "result"=>"clean site"}, "SecureBrain"=>{"detected"=>false, "result"=>"clean site"}, "Nucleon"=>{"detected"=>false, "result"=>"clean site"}, "PREBYTES"=>{"detected"=>false, "result"=>"clean site"}, "Sophos"=>{"detected"=>false, "result"=>"unrated site"}, "Blueliv"=>{"detected"=>false, "result"=>"clean site"}, "BlockList"=>{"detected"=>false, "result"=>"clean site"}, "Netcraft"=>{"detected"=>false, "result"=>"unrated site"}, "CRDF"=>{"detected"=>false, "result"=>"clean site"}, "ThreatHive"=>{"detected"=>false, "result"=>"clean site"}, "BADWARE.INFO"=>{"detected"=>false, "result"=>"clean site"}, "FraudScore"=>{"detected"=>false, "result"=>"clean site"}, "Quick Heal"=>{"detected"=>false, "result"=>"clean site"}, "Rising"=>{"detected"=>false, "result"=>"clean site"}, "StopBadware"=>{"detected"=>false, "result"=>"unrated site"}, "Sucuri SiteCheck"=>{"detected"=>false, "result"=>"clean site"}, "Fortinet"=>{"detected"=>true, "result"=>"phishing site"}, "StopForumSpam"=>{"detected"=>false, "result"=>"clean site"}, "ZeroCERT"=>{"detected"=>false, "result"=>"clean site"}, "Baidu-International"=>{"detected"=>false, "result"=>"clean site"}, "Phishing Database"=>{"detected"=>false, "result"=>"clean site"}}}
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
  let(:reptool_whitelist_good) {
    {"1.2.3.4"=>{"source"=>"From whitelist_ips in PostgreSQL", "comment"=>"", "status"=>"ACTIVE", "ident"=>"", "_id"=>"57165ecb673ca5a24b1b66db", "hostname"=>"google.com", "expiration"=>"NEVER"}}
  }
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
                            "rep_sugg"=>"Trusted",
                            "category"=>"Not in our list",
                            "claim" => "false positive"
                        },
                        "thepretenders.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Trusted",
                            "category"=>"Entertainment",
                            "claim" => "false positive"
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

  let(:umbrella_fp_json) do
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
                            "rep_sugg"=>"Trusted",
                            "suggested_threat_category" => "malware",
                            "claim" => "false positive",
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
                    product_platform: 2000,
                    network: false,
                    product_version: 'test'
                }
            }
        }
    }
  end
  let(:regular_umbrella_fp_json) do
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
                            "rep_sugg"=>"Trusted",
                            "suggested_threat_category" => "malware",
                            "claim" => "false positive",
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
                    product_platform: 2001,
                    network: false,
                    product_version: 'test'
                }
            }
        }
    }
  end


  let(:email_autoresolve_json) do
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

                    },
                    investigate_ips:{
                                     "2.3.4.5" => {
                                         "wbrs" => {
                                             "WBRS_SCORE"=>"-3.55",
                                             "WBRS_Rule_Hits"=>"dotq",
                                             "Hostname_ips"=>"",
                                             "rep_sugg"=>"Good",
                                             "category"=>"Not in our list"
                                         },
                                         "sbrs" => {
                                             "SBRS_SCORE"=>"-53",
                                             "SBRS_Rule_Hits"=>"DhH, IaM, Pbl",
                                             "Hostname"=>"www.dealer.com",
                                             "rep_sugg"=>"Good",
                                             "claim" => "false positive",
                                             "category"=>"Not in our list"
                                         }
                                     }
                    },
                    problem: 'What do I need to do to improve the reputation',
                    submission_type: 'e',
                    name: "test@test.com",
                    user_company: "Guest",
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
                            "claim" => "false negative",
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

  let(:umbrella_dispute_message_json_bad) do
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
                            "rep_sugg"=>"Untrusted",
                            "suggested_threat_category" => "malware",
                            "claim" => "false negative",
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
                    product_platform: 2000,
                    network: false,
                    product_version: 'test'
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
                            "suggested_threat_category" => "malware",
                            "claim" => "false negative",
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


  let(:mininum_ip_auto_resolve_json_allow) do
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
                        "1.2.3.4" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"wlw, wlm, wlh",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Poor",
                            "suggested_threat_category" => "malware",
                            "claim" => "false negative",
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

  let(:no_rules_ip_auto_resolve_json_allow) do
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
                        "1.2.3.4" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Poor",
                            "suggested_threat_category" => "malware",
                            "claim" => "false negative",
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

  before(:each) do
    Platform.destroy_all

    @umbrella_platform = Platform.new
    @umbrella_platform.id = 2000
    @umbrella_platform.public_name = "Umbrella - No Reply"
    @umbrella_platform.internal_name = "Umbrella - No Reply"
    @umbrella_platform.active = true
    @umbrella_platform.webrep = true
    @umbrella_platform.webcat = true
    @umbrella_platform.filerep = true
    @umbrella_platform.emailrep = true
    @umbrella_platform.save

    @umbrella_reg_platform = Platform.new
    @umbrella_reg_platform.id = 2001
    @umbrella_reg_platform.public_name = "Umbrella"
    @umbrella_reg_platform.internal_name = "Umbrella"
    @umbrella_reg_platform.active = true
    @umbrella_reg_platform.webrep = true
    @umbrella_reg_platform.webcat = true
    @umbrella_reg_platform.filerep = true
    @umbrella_reg_platform.emailrep = true
    @umbrella_reg_platform.save

  end

  #to do, find a domain that has a non blocking score to avoid the UNCHANGED auto resolution
  xit 'receives dispute payload message and does not auto resolve if there are no conditions' do
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
    expect(dispute_entry_2.status).to eql(DisputeEntry::STATUS_RESOLVED)
    expect(dispute_entry_2.resolution).to eql(DisputeEntry::STATUS_RESOLVED_UNCHANGED)
    expect(dispute_entry_2.suggested_threat_category).to eql(nil)

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
    expect(dispute_entry_1.resolution).to eql(DisputeEntry::STATUS_AUTO_RESOLVED_FN)

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
    expect(dispute_entry_1.suggested_threat_category).to eql('malware')
    expect(dispute_entry_1.resolution).to eql("")
    expect(dispute_entry_1.auto_resolve_log).to eql("--------Starting Data---------<br>suggested disposition: Poor<br>effective disposition info: \"Neutral\"<br>-----------------------------<br>Umbrella popularity rating: 0.0: result of pass: false<br><br>allow list hits from SDS detected: wlw,wlm,wlh")

  end

  it 'receives dispute payload message and auto resolves to UNCHANGED for umbrella no reply if rulehits are allow list types' do

    @umbrella_popular_bad = UmbrellaSecurityInfoResponse.new
    @umbrella_popular_bad.code = 200
    @umbrella_popular_bad.body = "{\"dga_score\":0.0,\"perplexity\":0.1698321879522074,\"entropy\":3.4594316186372978,\"securerank2\":0.0,\"pagerank\":0.0,\"asn_score\":-0.014739406284196042,\"prefix_score\":-0.023982712069696013,\"rip_score\":-0.011198019721606252,\"popularity\":0.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.5],[\"BR\",0.5]],\"geodiversity_normalized\":[[\"BR\",0.863526213328589],[\"US\",0.13647378667141086]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"


    expect(Umbrella::SecurityInfo).to receive(:query_info).with(address: "355toyota.com").and_return(@umbrella_popular_bad).at_least(:once)
    #expect(Virustotal::Scan).to receive(:scan_hashes).and_return(virus_total_conviction_hash).at_least(:once)
    #expect(RepApi::Whitelist).to receive(:get_whitelist_info).and_raise(RepApi::RepApiNotFoundError, "HTTP response 404").at_least(:once)

    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: umbrella_dispute_message_json_bad

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    expect(dispute.dispute_entries.where(uri: '355toyota.com')).to exist


    dispute_entry_1 = DisputeEntry.where(:uri => '355toyota.com').first

    expect(dispute_entry_1.status).to eql(DisputeEntry::STATUS_RESOLVED)
    expect(dispute_entry_1.resolution).to eql(DisputeEntry::STATUS_AUTO_RESOLVED_UNCHANGED)

    expect(dispute_entry_1.resolution_comment).to eql("Talos has not found sufficient evidence to modify the current reputation of the submission; we cannot change the submission’s reputation because it can negatively affect our customers. However, a customer has the option of locally changing a submission’s reputation, if they understand the risks in doing so. Please open a TAC case and provide additional details if you need further assistance.")
    expect(dispute_entry_1.suggested_threat_category).to eql('malware')
    expect(dispute_entry_1.auto_resolve_log).to eql("--------Starting Data---------<br>suggested disposition: Untrusted<br>effective disposition info: \"Neutral\"<br>-----------------------------<br>Umbrella popularity rating: 0.0: result of pass: false<br><br>allow list hits from SDS detected: wlw,wlm,wlh")

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

  it 'received dispute payload and auto resolves unchanged for false positive umbrella no reply cases' do

    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: umbrella_fp_json

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    expect(dispute.dispute_entries.where(uri: '355toyota.com')).to exist


    dispute_entry_1 = DisputeEntry.where(:uri => '355toyota.com').first

    expect(dispute_entry_1.status).to eql("RESOLVED_CLOSED")

    expect(dispute_entry_1.resolution).to eql(DisputeEntry::STATUS_AUTO_RESOLVED_UNCHANGED)
    expect(dispute_entry_1.resolution_comment).to eql("The following ticket queue is for false negative requests only. If you would like to dispute the reputation of an Untrusted verdict, please open a Web Reputation ticket.")

  end

  it 'received dispute payload and sets to new for false positive standard (not no-reply) umbrella cases' do
    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: regular_umbrella_fp_json

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    expect(dispute.dispute_entries.where(uri: '355toyota.com')).to exist


    dispute_entry_1 = DisputeEntry.where(:uri => '355toyota.com').first

    expect(dispute_entry_1.status).to eql("NEW")
    expect(dispute_entry_1.resolution).to eql("")
    expect(dispute_entry_1.resolution_comment).to eql(nil)
  end

  it 'received dispute payload and auto resolves email false positive' do


    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: email_autoresolve_json

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    expect(dispute.dispute_entries.where(ip_address: '2.3.4.5')).to exist


    dispute_entry_1 = DisputeEntry.where(:ip_address => '2.3.4.5').first

    expect(dispute_entry_1.status).to eql("RESOLVED_CLOSED")

    expect(dispute_entry_1.resolution).to eql(DisputeEntry::STATUS_AUTO_RESOLVED_UNCHANGED)
    expect(dispute_entry_1.resolution_comment).to eql("Our worldwide sensor network indicates that spam originated from your IP. In addition, our sensors indicate server access attempts from this IP to mail servers within our Sensor Network. This behavior is indicative of email directory harvesting attempts and also results in reputation impact to the IP. Directory harvest detection fires when you are sending to invalid email addresses. It is possible that your network or a system in your network may be compromised by a trojan spam virus, or perhaps there is an open port 25 through which a spammer may be gaining access and sending out spam. The last possibility is that one of your users is sending spam through the IP. We suggest checking these possibilities to help isolate the root cause of the spam and mail server access attempts originating from your IP. In general, once all issues have been addressed (fixed), reputation recovery can take anywhere from a few hours to just over one week to improve, depending on the specifics of the situation, and how much email volume the IP sends. Complaint ratios determine the amount of risk for receiving mail from an IP, so logically, reputation improves as the ratio of legitimate mails increases with respect to the number of complaints. Speeding up the process is not really possible. Talos Intelligence Reputation is an automated system over which we have very little manual influence. Your IP has a poor Talos Intelligence Reputation due to currently being listed on Spamhaus (http://www.spamhaus.org/) Review the status and reason(s) by visiting https://www.spamhaus.org/lookup/and entering your IP. Please contact Spamhaus directly to resolve this listing issue. Once delisted, the Talos Intelligence Reputation for the IP should improve within 24 hours.")

  end

  xit 'should use umbrella no reply auto resolution for umbrella no reply tickets' do

    umbrella_popular_bad = UmbrellaSecurityInfoResponse.new
    umbrella_popular_bad.code = 200
    umbrella_popular_bad.body = "{\"dga_score\":0.0,\"perplexity\":0.1698321879522074,\"entropy\":3.4594316186372978,\"securerank2\":0.0,\"pagerank\":0.0,\"asn_score\":-0.014739406284196042,\"prefix_score\":-0.023982712069696013,\"rip_score\":-0.011198019721606252,\"popularity\":0.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.5],[\"BR\",0.5]],\"geodiversity_normalized\":[[\"BR\",0.863526213328589],[\"US\",0.13647378667141086]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"

    umbrella_volume_bad = UmbrellaVolumeResponse.new
    umbrella_volume_bad.code = 200
    umbrella_volume_bad.body = "{\"dates\":[1624107600000,1626699600000],\"queries\":[0,0,1,2,0,1,0,0,0,1,0,0,0,0,0,0,2,0,0,0,0,0,0,5,0,0,0,0,0,6,0,0,5,0,0,5,0,0,3,0,0,5,0,0,9,0,0,5,0,0,3,0,3,1,0,4,0,0,3,0,0,5,0,0,5,0,0,6,0,0,4,0,0,4,0,0,2,0,0,4,0,0,2,0,0,4,0,0,5,0,0,6,0,0,6,0,0,3,2,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,1,1,0,2,0,0,0,0,0,0,1,2,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,4,0,1,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,10,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,19,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,1,0,1,0,0,0,2,1,0,0,0,0,0,0,0,1,1,0,1,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]}"

    xena_allow_list = false

    expect(Umbrella::SecurityInfo).to receive(:query_info).with(address: "355toyota.com").and_return(umbrella_popular_bad).at_least(:once)
    #expect(Virustotal::Scan).to receive(:scan_hashes).and_return(virus_total_conviction_hash).at_least(:once)
    expect(RepApi::Whitelist).to receive(:get_whitelist_info).and_raise(RepApi::RepApiNotFoundError, "HTTP response 404").at_least(:once)
    #expect(Xena::GuardRails).to receive(:is_allow_listed?).and_return(xena_allow_list).at_least(:once)
    expect(Umbrella::DomainVolume).to receive(:query_domain_volume).and_return(umbrella_volume_bad).at_least(:once)


    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: umbrella_dispute_message_json_bad

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    expect(dispute.dispute_entries.where(uri: '355toyota.com')).to exist

    dispute_entry_1 = DisputeEntry.where(:uri => '355toyota.com').first

    expect(dispute_entry_1.status).to eql(DisputeEntry::STATUS_RESOLVED)
    expect(dispute_entry_1.resolution).to eql(DisputeEntry::STATUS_RESOLVED_FIXED_FN)

    expect(dispute_entry_1.auto_resolve_log).to eql("--------Starting Data---------<br>suggested disposition: Untrusted<br>effective disposition info: \"Neutral\"<br>-----------------------------<br>Umbrella popularity rating: 0.0: result of pass: false<br><br>no sds rulehits detected against allow list<br><br>no entry with reptool whitelist, continuing.<br><br>no allow list entry on xena, continuing<br><br>found no signs of high volume, proceed to auto resolve")

  end

  xit 'should use umbrella no reply auto resolution for umbrella no reply tickets, no auto resolve from high volume' do

    umbrella_popular_bad = UmbrellaSecurityInfoResponse.new
    umbrella_popular_bad.code = 200
    umbrella_popular_bad.body = "{\"dga_score\":0.0,\"perplexity\":0.1698321879522074,\"entropy\":3.4594316186372978,\"securerank2\":0.0,\"pagerank\":0.0,\"asn_score\":-0.014739406284196042,\"prefix_score\":-0.023982712069696013,\"rip_score\":-0.011198019721606252,\"popularity\":0.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.5],[\"BR\",0.5]],\"geodiversity_normalized\":[[\"BR\",0.863526213328589],[\"US\",0.13647378667141086]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"

    umbrella_volume_bad = UmbrellaVolumeResponse.new
    umbrella_volume_bad.code = 200
    umbrella_volume_bad.body = "{\"dates\":[1624107600000,1626699600000],\"queries\":[0,0,100,400,100,100,0,100,100,100,0,0,0,0,0,0,2,0,0,0,0,0,0,5,0,0,0,0,0,6,0,0,5,0,0,5,0,0,3,0,0,5,0,0,9,0,0,5,0,0,3,0,3,1,0,4,0,0,3,0,0,5,0,0,5,0,0,6,0,0,4,0,0,4,0,0,2,0,0,4,0,0,2,0,0,4,0,0,5,0,0,6,0,0,6,0,0,3,2,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,1,1,0,2,0,0,0,0,0,0,1,2,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,4,0,1,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,10,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,19,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,1,0,1,0,0,0,2,1,0,0,0,0,0,0,0,1,1,0,1,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,99,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,5,0,0,0,0,0,0,0,0,0,0,99,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,8,0,0,99,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,99,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,99,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]}"

    xena_allow_list = false


    expect(Umbrella::SecurityInfo).to receive(:query_info).with(address: "355toyota.com").and_return(umbrella_popular_bad).at_least(:once)
    #expect(Virustotal::Scan).to receive(:scan_hashes).and_return(virus_total_conviction_hash).at_least(:once)
    expect(RepApi::Whitelist).to receive(:get_whitelist_info).and_raise(RepApi::RepApiNotFoundError, "HTTP response 404").at_least(:once)
    expect(Xena::GuardRails).to receive(:is_allow_listed?).and_return(xena_allow_list).at_least(:once)
    expect(Umbrella::DomainVolume).to receive(:query_domain_volume).and_return(umbrella_volume_bad).at_least(:once)


    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: umbrella_dispute_message_json_bad

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    expect(dispute.dispute_entries.where(uri: '355toyota.com')).to exist

    dispute_entry_1 = DisputeEntry.where(:uri => '355toyota.com').first

    expect(dispute_entry_1.status).to eql(DisputeEntry::NEW)
    expect(dispute_entry_1.resolution).to eql("")

    expect(dispute_entry_1.auto_resolve_log).to eql("--------Starting Data---------<br>suggested disposition: Untrusted<br>effective disposition info: \"Neutral\"<br>-----------------------------<br>Umbrella popularity rating: 0.0: result of pass: false<br><br>no sds rulehits detected against allow list<br><br>no entry with reptool whitelist, continuing.<br><br>no allow list entry on xena, continuing<br><br>found high volume in day and month, send to TE for manual review")

  end

  xit 'should use umbrella no reply auto resolution for umbrella no reply tickets, no auto resolve from xena match' do

    umbrella_popular_bad = UmbrellaSecurityInfoResponse.new
    umbrella_popular_bad.code = 200
    umbrella_popular_bad.body = "{\"dga_score\":0.0,\"perplexity\":0.1698321879522074,\"entropy\":3.4594316186372978,\"securerank2\":0.0,\"pagerank\":0.0,\"asn_score\":-0.014739406284196042,\"prefix_score\":-0.023982712069696013,\"rip_score\":-0.011198019721606252,\"popularity\":0.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.5],[\"BR\",0.5]],\"geodiversity_normalized\":[[\"BR\",0.863526213328589],[\"US\",0.13647378667141086]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"

    umbrella_volume_bad = UmbrellaVolumeResponse.new
    umbrella_volume_bad.code = 200
    umbrella_volume_bad.body = umbrella_volume_bad.body = "{\"dates\":[1624107600000,1626699600000],\"queries\":[0,0,1,2,0,1,0,0,0,1,0,0,0,0,0,0,2,0,0,0,0,0,0,5,0,0,0,0,0,6,0,0,5,0,0,5,0,0,3,0,0,5,0,0,9,0,0,5,0,0,3,0,3,1,0,4,0,0,3,0,0,5,0,0,5,0,0,6,0,0,4,0,0,4,0,0,2,0,0,4,0,0,2,0,0,4,0,0,5,0,0,6,0,0,6,0,0,3,2,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,1,1,0,2,0,0,0,0,0,0,1,2,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,4,0,1,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,10,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,19,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,1,0,1,0,0,0,2,1,0,0,0,0,0,0,0,1,1,0,1,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]}"

    xena_allow_list = true


    expect(Umbrella::SecurityInfo).to receive(:query_info).with(address: "355toyota.com").and_return(umbrella_popular_bad).at_least(:once)
    #expect(Virustotal::Scan).to receive(:scan_hashes).and_return(virus_total_conviction_hash).at_least(:once)
    expect(RepApi::Whitelist).to receive(:get_whitelist_info).and_raise(RepApi::RepApiNotFoundError, "HTTP response 404").at_least(:once)
    expect(Xena::GuardRails).to receive(:is_allow_listed?).and_return(xena_allow_list).at_least(:once)
    #expect(Umbrella::DomainVolume).to receive(:query_domain_volume).and_return(umbrella_volume_bad).at_least(:once)


    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: umbrella_dispute_message_json_bad

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    expect(dispute.dispute_entries.where(uri: '355toyota.com')).to exist

    dispute_entry_1 = DisputeEntry.where(:uri => '355toyota.com').first

    expect(dispute_entry_1.status).to eql(DisputeEntry::NEW)
    expect(dispute_entry_1.resolution).to eql("")

    expect(dispute_entry_1.auto_resolve_log).to eql("--------Starting Data---------<br>suggested disposition: Untrusted<br>effective disposition info: \"Neutral\"<br>-----------------------------<br>Umbrella popularity rating: 0.0: result of pass: false<br><br>no sds rulehits detected against allow list<br><br>no entry with reptool whitelist, continuing.<br><br>allow listed on xena, manual review")

  end

  ##################################new ip based web FN#####################################

  it 'should send to TE if in allow list SDS' do
    @umbrella_popular_bad = UmbrellaSecurityInfoResponse.new
    @umbrella_popular_bad.code = 200
    @umbrella_popular_bad.body = "{\"dga_score\":0.0,\"perplexity\":0.1698321879522074,\"entropy\":3.4594316186372978,\"securerank2\":0.0,\"pagerank\":0.0,\"asn_score\":-0.014739406284196042,\"prefix_score\":-0.023982712069696013,\"rip_score\":-0.011198019721606252,\"popularity\":0.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.5],[\"BR\",0.5]],\"geodiversity_normalized\":[[\"BR\",0.863526213328589],[\"US\",0.13647378667141086]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"


    #expect(Umbrella::SecurityInfo).to receive(:query_info).with(address: "1.2.3.4").and_return(@umbrella_popular_bad).at_least(:once)
    #expect(Virustotal::Scan).to receive(:scan_hashes).and_return(virus_total_conviction_hash).at_least(:once)
    #expect(RepApi::Whitelist).to receive(:get_whitelist_info).and_raise(RepApi::RepApiNotFoundError, "HTTP response 404").at_least(:once)

    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: mininum_ip_auto_resolve_json_allow

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    expect(dispute.dispute_entries.where(uri: '1.2.3.4')).to exist


    dispute_entry_1 = DisputeEntry.where(:uri => '1.2.3.4').first

    expect(dispute_entry_1.status).to eql(DisputeEntry::NEW)
    expect(dispute_entry_1.auto_resolve_log).to eql("--------Starting Data---------<br>suggested disposition: Poor<br>effective disposition info: \"Neutral\"<br>-----------------------------<br>allow list hits from SDS detected: wlw,wlm,wlh")
  end

  it 'should send to TE if in allow list reptool' do
    @umbrella_popular_bad = UmbrellaSecurityInfoResponse.new
    @umbrella_popular_bad.code = 200
    @umbrella_popular_bad.body = "{\"dga_score\":0.0,\"perplexity\":0.1698321879522074,\"entropy\":3.4594316186372978,\"securerank2\":0.0,\"pagerank\":0.0,\"asn_score\":-0.014739406284196042,\"prefix_score\":-0.023982712069696013,\"rip_score\":-0.011198019721606252,\"popularity\":0.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.5],[\"BR\",0.5]],\"geodiversity_normalized\":[[\"BR\",0.863526213328589],[\"US\",0.13647378667141086]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"


    #expect(Umbrella::SecurityInfo).to receive(:query_info).with(address: "1.2.3.4").and_return(@umbrella_popular_bad).at_least(:once)
    #expect(Virustotal::Scan).to receive(:scan_hashes).and_return(virus_total_conviction_hash).at_least(:once)
    #expect(RepApi::Whitelist).to receive(:get_whitelist_info).and_raise(RepApi::RepApiNotFoundError, "HTTP response 404").at_least(:once)
    expect(RepApi::Whitelist).to receive(:get_whitelist_info).with({:entries => ["1.2.3.4"]}).and_return(reptool_whitelist_good).at_least(:once)
    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: no_rules_ip_auto_resolve_json_allow

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    expect(dispute.dispute_entries.where(uri: '1.2.3.4')).to exist


    dispute_entry_1 = DisputeEntry.where(:uri => '1.2.3.4').first

    expect(dispute_entry_1.status).to eql(DisputeEntry::NEW)

    expect(dispute_entry_1.auto_resolve_log).to eql("--------Starting Data---------<br>suggested disposition: Poor<br>effective disposition info: \"Neutral\"<br>-----------------------------<br>no sds rulehits detected against allow list<br><br>ACTIVE entry on Reptool whitelist, manual review.")
  end

  it 'should send to TE if VT hits < 12 and hosted malicious domain less than 70% (more than 100 domains)' do

    domain_list = "{\"recordInfo\":{\"totalMaliciousDomain\":2},\"features\":{\"rr_count\":101}}"

    expect(Virustotal::Scan).to receive(:scan_hashes).and_return(virus_total_nonconviction_hash).at_least(:once)
    expect(RepApi::Whitelist).to receive(:get_whitelist_info).and_raise(RepApi::RepApiNotFoundError, "HTTP response 404").at_least(:once)
    expect(Umbrella::SecurityInfo).to receive(:query_malicious_domains).and_return(domain_list).at_least(:once)
    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: no_rules_ip_auto_resolve_json_allow

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    expect(dispute.dispute_entries.where(uri: '1.2.3.4')).to exist


    dispute_entry_1 = DisputeEntry.where(:uri => '1.2.3.4').first

    expect(dispute_entry_1.status).to eql(DisputeEntry::NEW)

    expect(dispute_entry_1.auto_resolve_log).to eql("--------Starting Data---------<br>suggested disposition: Poor<br>effective disposition info: \"Neutral\"<br>-----------------------------<br>no sds rulehits detected against allow list<br><br>no entry with reptool whitelist, continuing.<br><br>malicious domain ratio was under 70%")
  end

  it 'should send to TE if VT hits < 3 and umbrella rating is not bad and not on asn block list hosted malicious domain less than 20% (less than 100 domains and  hihgest popularity < 40' do

    umbrella_scan_good = UmbrellaScanResponse.new
    umbrella_scan_good.code = 200
    umbrella_scan_good.body = "{\"google.com\":{\"status\":1,\"security_categories\":[],\"content_categories\":[\"23\"]}}"

    @umbrella_popular_bad = UmbrellaSecurityInfoResponse.new
    @umbrella_popular_bad.code = 200
    @umbrella_popular_bad.body = "{\"dga_score\":0.0,\"perplexity\":0.1698321879522074,\"entropy\":3.4594316186372978,\"securerank2\":0.0,\"pagerank\":0.0,\"asn_score\":-0.014739406284196042,\"prefix_score\":-0.023982712069696013,\"rip_score\":-0.011198019721606252,\"popularity\":0.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.5],[\"BR\",0.5]],\"geodiversity_normalized\":[[\"BR\",0.863526213328589],[\"US\",0.13647378667141086]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"


    umbrella_popular_good = UmbrellaSecurityInfoResponse.new
    umbrella_popular_good.code = 200
    umbrella_popular_good.body = "{\"dga_score\":0.0,\"perplexity\":0.18786756104373362,\"entropy\":1.9182958340544896,\"securerank2\":100.0,\"pagerank\":63.36242,\"asn_score\":-0.07587332170749107,\"prefix_score\":-0.02867604643567799,\"rip_score\":-0.12451293522019732,\"popularity\":100.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.3591],[\"BR\",0.1046],[\"IN\",0.0603],[\"CA\",0.0358],[\"GB\",0.0344],[\"EG\",0.0288],[\"TR\",0.0216],[\"VN\",0.0202],[\"IT\",0.02],[\"MX\",0.0169],[\"DE\",0.0162],[\"FR\",0.0152],[\"AU\",0.0138],[\"JP\",0.0129],[\"PH\",0.0126],[\"RU\",0.0113],[\"ES\",0.0106],[\"IR\",0.0098],[\"NL\",0.0085],[\"PL\",0.0085],[\"ID\",0.0072],[\"CN\",0.0071],[\"AR\",0.007],[\"MY\",0.007],[\"UA\",0.0068],[\"DZ\",0.0064],[\"CO\",0.0056],[\"EC\",0.0053],[\"ZA\",0.005],[\"PT\",0.0047],[\"SE\",0.0045],[\"SA\",0.0039],[\"TH\",0.0038],[\"BE\",0.0037],[\"SG\",0.0036],[\"CL\",0.0036],[\"VE\",0.0035],[\"DK\",0.0033],[\"PE\",0.0032],[\"MA\",0.0031],[\"IE\",0.0031],[\"IL\",0.0029],[\"YE\",0.0027],[\"CH\",0.0026],[\"RO\",0.0024],[\"HK\",0.0024],[\"GR\",0.0023],[\"CZ\",0.0023],[\"TW\",0.0021],[\"AE\",0.0021],[\"PK\",0.0021],[\"AT\",0.002],[\"NZ\",0.002],[\"HU\",0.002],[\"NO\",0.0019],[\"KZ\",0.0017],[\"??\",0.0016],[\"AF\",0.0016],[\"KR\",0.0016],[\"CR\",0.0015],[\"IQ\",0.0015],[\"BM\",0.0014],[\"UY\",0.0013],[\"SK\",0.0012],[\"DO\",0.0011],[\"TT\",0.001],[\"BG\",0.001],[\"BD\",0.001],[\"LK\",0.001],[\"BY\",9.0E-4],[\"TN\",9.0E-4],[\"NG\",9.0E-4],[\"FI\",8.0E-4],[\"PR\",8.0E-4],[\"SY\",8.0E-4],[\"RS\",8.0E-4],[\"JO\",8.0E-4],[\"GT\",7.0E-4],[\"BA\",7.0E-4],[\"BO\",7.0E-4],[\"LT\",7.0E-4],[\"KE\",7.0E-4],[\"LB\",7.0E-4],[\"UZ\",6.0E-4],[\"QA\",6.0E-4],[\"SD\",6.0E-4],[\"LY\",6.0E-4],[\"NP\",6.0E-4],[\"OM\",5.0E-4],[\"PA\",5.0E-4],[\"HN\",5.0E-4],[\"HR\",5.0E-4],[\"ET\",4.0E-4],[\"GH\",4.0E-4],[\"AZ\",4.0E-4],[\"PS\",4.0E-4],[\"AL\",4.0E-4],[\"PY\",4.0E-4],[\"SI\",4.0E-4],[\"BZ\",3.0E-4],[\"SV\",3.0E-4],[\"CI\",3.0E-4],[\"JM\",3.0E-4],[\"KW\",3.0E-4],[\"EE\",2.0E-4],[\"GE\",2.0E-4],[\"AO\",2.0E-4],[\"BW\",2.0E-4],[\"BH\",2.0E-4],[\"CY\",2.0E-4],[\"SN\",2.0E-4],[\"LV\",2.0E-4],[\"LU\",2.0E-4],[\"MK\",2.0E-4],[\"MD\",2.0E-4],[\"MU\",2.0E-4],[\"MM\",2.0E-4],[\"MT\",2.0E-4],[\"NA\",2.0E-4],[\"IS\",2.0E-4],[\"KH\",2.0E-4],[\"DJ\",1.0E-4],[\"UG\",1.0E-4],[\"TZ\",1.0E-4],[\"GY\",1.0E-4],[\"GU\",1.0E-4],[\"GP\",1.0E-4],[\"RE\",1.0E-4],[\"AM\",1.0E-4],[\"TG\",1.0E-4],[\"BS\",1.0E-4],[\"BB\",1.0E-4],[\"BN\",1.0E-4],[\"BJ\",1.0E-4],[\"CW\",1.0E-4],[\"CD\",1.0E-4],[\"CM\",1.0E-4],[\"ME\",1.0E-4],[\"MV\",1.0E-4],[\"MZ\",1.0E-4],[\"MO\",1.0E-4],[\"MQ\",1.0E-4],[\"NI\",1.0E-4],[\"NE\",1.0E-4],[\"HT\",1.0E-4],[\"ZM\",1.0E-4],[\"ZW\",1.0E-4],[\"JE\",1.0E-4],[\"KG\",1.0E-4],[\"KY\",1.0E-4],[\"LA\",1.0E-4]],\"geodiversity_normalized\":[[\"BM\",0.20375896159233017],[\"YE\",0.09244116857647527],[\"LY\",0.03906714839945628],[\"JP\",0.030247161175715482],[\"UY\",0.017327997941008564],[\"GP\",0.01611794734153928],[\"OM\",0.01584445948550431],[\"UZ\",0.012655753260989624],[\"ZA\",0.012459173513181756],[\"NA\",0.012353255907166424],[\"DJ\",0.012059048193487418],[\"ET\",0.011267448269447748],[\"NE\",0.011130948345478668],[\"TG\",0.011115586042923016],[\"MQ\",0.010917816571685718],[\"CD\",0.010133128017268738],[\"IR\",0.009554115786249174],[\"GY\",0.009020860272706092],[\"ZW\",0.008999440533249985],[\"JO\",0.008587359427940694],[\"CI\",0.008458906984088651],[\"EC\",0.008424890295545056],[\"ZM\",0.008062503221898677],[\"QA\",0.007927753403880314],[\"MA\",0.007834061862256707],[\"SD\",0.007603882043760343],[\"SA\",0.007515213996104046],[\"IL\",0.007413411654412088],[\"NP\",0.0073149722224984315],[\"LB\",0.006992890545058264],[\"PH\",0.006975493060458157],[\"TT\",0.006877277598164459],[\"MM\",0.00672071497838774],[\"NZ\",0.006606545844889045],[\"AU\",0.006420955278274985],[\"SN\",0.005953888649969115],[\"GU\",0.005444608289488192],[\"PY\",0.005383647601754953],[\"BJ\",0.005373769349274668],[\"AM\",0.005345902883036986],[\"ME\",0.0051186887386536865],[\"IN\",0.005105527493742024],[\"LK\",0.005030075492148507],[\"BZ\",0.005025008344752182],[\"MU\",0.004938319913989788],[\"SG\",0.004904747993133913],[\"BH\",0.0048228971516750836],[\"KW\",0.004798889830765654],[\"EG\",0.004619340709342588],[\"BR\",0.004599468222743493],[\"AT\",0.004540410833015574],[\"GH\",0.004520279187084444],[\"HU\",0.0045116381878804275],[\"GE\",0.004497835567036878],[\"KE\",0.004491586986786001],[\"AE\",0.004484969188213879],[\"MT\",0.004350760132876633],[\"CO\",0.0043249507554260005],[\"PT\",0.0043077022802489266],[\"MD\",0.00428657404682345],[\"MZ\",0.004127445917671008],[\"TN\",0.0038572622599467817],[\"BD\",0.0038168055504889087],[\"PE\",0.003802764959897941],[\"GT\",0.0037809849520660166],[\"BO\",0.0037776439081732686],[\"RE\",0.0037705696686448544],[\"IS\",0.0037224273209199416],[\"CZ\",0.0037113614866476213],[\"SY\",0.003700792682319089],[\"MO\",0.0036077884818748684],[\"ES\",0.0035846536395296663],[\"MX\",0.0035827810660169703],[\"BW\",0.0035818656343892972],[\"CL\",0.003554849247808106],[\"DE\",0.003531979589799978],[\"GR\",0.003524631758147203],[\"IQ\",0.0034449203973161615],[\"HK\",0.0034358080966143713],[\"KG\",0.0032849747373204486],[\"JE\",0.003256006998903569],[\"HR\",0.0032409882444745662],[\"VE\",0.0032242854277104603],[\"SV\",0.0031234464489522467],[\"KR\",0.003049835621805406],[\"AF\",0.003036249637633131],[\"RO\",0.002997571804394868],[\"CH\",0.002979705709246971],[\"KZ\",0.0029703044415169007],[\"BE\",0.0029144025985733658],[\"MV\",0.0028368296972065285],[\"CR\",0.002776258271107416],[\"BB\",0.0027733942190858846],[\"AZ\",0.0027669033344557264],[\"LT\",0.0027166143334635736],[\"FR\",0.002678444359267468],[\"KY\",0.002611575887068207],[\"HN\",0.002598002229714169],[\"FI\",0.002592164727092915],[\"KH\",0.0025637233207784207],[\"SE\",0.002559739783173962],[\"HT\",0.0025571097550423963],[\"US\",0.0024955430120255106],[\"UG\",0.0024637310529903363],[\"DO\",0.002447096492825564],[\"PA\",0.0024279688323486756],[\"NL\",0.0023297394861225263],[\"EE\",0.002320455022564876],[\"IE\",0.0023053956285744802],[\"SI\",0.002304148999054233],[\"RS\",0.0022736983175376756],[\"PS\",0.002254662648206714],[\"TW\",0.002188166300297028],[\"TZ\",0.0021626386902226457],[\"AO\",0.0021310410867562417],[\"SK\",0.0019483833374038515],[\"CA\",0.0019178395715433397],[\"BY\",0.0019097823579033273],[\"MY\",0.0018519651455630832],[\"AL\",0.0018296669943540411],[\"AR\",0.001817066969918926],[\"GB\",0.001795893396906611],[\"CY\",0.0017925147482679188],[\"LA\",0.0017850531790498205],[\"TH\",0.0017688191331781708],[\"LV\",0.0017597982819709738],[\"PL\",0.0017570479059798101],[\"JM\",0.0017179364931356996],[\"NO\",0.0016701570504380208],[\"LU\",0.0015553395089509797],[\"IT\",0.0014440301311380746],[\"NG\",0.0013904044024260944],[\"UA\",0.0013449056884677643],[\"BA\",0.0012723618350648786],[\"MK\",0.0012578380153405292],[\"??\",0.00124098909424614],[\"BS\",0.0011379132764855538],[\"PR\",0.0011252738806954998],[\"VN\",0.0011050924675411258],[\"PK\",0.0010718205066905487],[\"RU\",0.0010681750932449397],[\"ID\",9.676335777603613E-4],[\"BG\",9.381747224025812E-4],[\"CN\",8.529633575726018E-4],[\"DK\",8.518203079498652E-4],[\"CW\",7.487854976037012E-4],[\"DZ\",6.800142031102517E-4],[\"TR\",5.295034276648443E-4],[\"CM\",3.475859949117745E-4],[\"BN\",3.384718139199583E-4],[\"NI\",2.8908538206708653E-4]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"

    #domain_list = "{\"recordInfo\":{\"totalMaliciousDomain\":2},\"features\":{\"rr_count\":95}}"
    domain_list = "{\"recordInfo\":{\"totalMaliciousDomain\":2},\"features\":{\"rr_count\":95},\"records\":[{\"rr\":\"abc.com\"},{\"rr\":\"abc1.com\"}]}"
    expect(Virustotal::Scan).to receive(:scan_hashes).and_return(virus_total_nonconviction_hash).at_least(:once)
    expect(RepApi::Whitelist).to receive(:get_whitelist_info).and_raise(RepApi::RepApiNotFoundError, "HTTP response 404").at_least(:once)
    expect(Umbrella::SecurityInfo).to receive(:query_malicious_domains).and_return(domain_list).at_least(:once)
    expect(Umbrella::Scan).to receive(:scan_result).with(address: "1.2.3.4").and_return(umbrella_scan_good).at_least(:once)

    expect(Umbrella::SecurityInfo).to receive(:query_info).and_return(@umbrella_popular_bad).at_least(:once)

    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: no_rules_ip_auto_resolve_json_allow

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    expect(dispute.dispute_entries.where(uri: '1.2.3.4')).to exist


    dispute_entry_1 = DisputeEntry.where(:uri => '1.2.3.4').first

    expect(dispute_entry_1.status).to eql(DisputeEntry::NEW)

    expect(dispute_entry_1.auto_resolve_log).to eql("--------Starting Data---------<br>suggested disposition: Poor<br>effective disposition info: \"Neutral\"<br>-----------------------------<br>no sds rulehits detected against allow list<br><br>no entry with reptool whitelist, continuing.<br><br>virustotal hits under thresholds<br><br>not found in spamhaus list<br><br>malicious domain ratio was under 20%")

  end

  ##############

  it 'should auto resolve if hosted domains > 100 and vt htis >= 12 or VT trusted hits >= 2' do
    umbrella_scan_good = UmbrellaScanResponse.new
    umbrella_scan_good.code = 200
    umbrella_scan_good.body = "{\"google.com\":{\"status\":1,\"security_categories\":[],\"content_categories\":[\"23\"]}}"

    @umbrella_popular_bad = UmbrellaSecurityInfoResponse.new
    @umbrella_popular_bad.code = 200
    @umbrella_popular_bad.body = "{\"dga_score\":0.0,\"perplexity\":0.1698321879522074,\"entropy\":3.4594316186372978,\"securerank2\":0.0,\"pagerank\":0.0,\"asn_score\":-0.014739406284196042,\"prefix_score\":-0.023982712069696013,\"rip_score\":-0.011198019721606252,\"popularity\":0.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.5],[\"BR\",0.5]],\"geodiversity_normalized\":[[\"BR\",0.863526213328589],[\"US\",0.13647378667141086]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"


    umbrella_popular_good = UmbrellaSecurityInfoResponse.new
    umbrella_popular_good.code = 200
    umbrella_popular_good.body = "{\"dga_score\":0.0,\"perplexity\":0.18786756104373362,\"entropy\":1.9182958340544896,\"securerank2\":100.0,\"pagerank\":63.36242,\"asn_score\":-0.07587332170749107,\"prefix_score\":-0.02867604643567799,\"rip_score\":-0.12451293522019732,\"popularity\":100.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.3591],[\"BR\",0.1046],[\"IN\",0.0603],[\"CA\",0.0358],[\"GB\",0.0344],[\"EG\",0.0288],[\"TR\",0.0216],[\"VN\",0.0202],[\"IT\",0.02],[\"MX\",0.0169],[\"DE\",0.0162],[\"FR\",0.0152],[\"AU\",0.0138],[\"JP\",0.0129],[\"PH\",0.0126],[\"RU\",0.0113],[\"ES\",0.0106],[\"IR\",0.0098],[\"NL\",0.0085],[\"PL\",0.0085],[\"ID\",0.0072],[\"CN\",0.0071],[\"AR\",0.007],[\"MY\",0.007],[\"UA\",0.0068],[\"DZ\",0.0064],[\"CO\",0.0056],[\"EC\",0.0053],[\"ZA\",0.005],[\"PT\",0.0047],[\"SE\",0.0045],[\"SA\",0.0039],[\"TH\",0.0038],[\"BE\",0.0037],[\"SG\",0.0036],[\"CL\",0.0036],[\"VE\",0.0035],[\"DK\",0.0033],[\"PE\",0.0032],[\"MA\",0.0031],[\"IE\",0.0031],[\"IL\",0.0029],[\"YE\",0.0027],[\"CH\",0.0026],[\"RO\",0.0024],[\"HK\",0.0024],[\"GR\",0.0023],[\"CZ\",0.0023],[\"TW\",0.0021],[\"AE\",0.0021],[\"PK\",0.0021],[\"AT\",0.002],[\"NZ\",0.002],[\"HU\",0.002],[\"NO\",0.0019],[\"KZ\",0.0017],[\"??\",0.0016],[\"AF\",0.0016],[\"KR\",0.0016],[\"CR\",0.0015],[\"IQ\",0.0015],[\"BM\",0.0014],[\"UY\",0.0013],[\"SK\",0.0012],[\"DO\",0.0011],[\"TT\",0.001],[\"BG\",0.001],[\"BD\",0.001],[\"LK\",0.001],[\"BY\",9.0E-4],[\"TN\",9.0E-4],[\"NG\",9.0E-4],[\"FI\",8.0E-4],[\"PR\",8.0E-4],[\"SY\",8.0E-4],[\"RS\",8.0E-4],[\"JO\",8.0E-4],[\"GT\",7.0E-4],[\"BA\",7.0E-4],[\"BO\",7.0E-4],[\"LT\",7.0E-4],[\"KE\",7.0E-4],[\"LB\",7.0E-4],[\"UZ\",6.0E-4],[\"QA\",6.0E-4],[\"SD\",6.0E-4],[\"LY\",6.0E-4],[\"NP\",6.0E-4],[\"OM\",5.0E-4],[\"PA\",5.0E-4],[\"HN\",5.0E-4],[\"HR\",5.0E-4],[\"ET\",4.0E-4],[\"GH\",4.0E-4],[\"AZ\",4.0E-4],[\"PS\",4.0E-4],[\"AL\",4.0E-4],[\"PY\",4.0E-4],[\"SI\",4.0E-4],[\"BZ\",3.0E-4],[\"SV\",3.0E-4],[\"CI\",3.0E-4],[\"JM\",3.0E-4],[\"KW\",3.0E-4],[\"EE\",2.0E-4],[\"GE\",2.0E-4],[\"AO\",2.0E-4],[\"BW\",2.0E-4],[\"BH\",2.0E-4],[\"CY\",2.0E-4],[\"SN\",2.0E-4],[\"LV\",2.0E-4],[\"LU\",2.0E-4],[\"MK\",2.0E-4],[\"MD\",2.0E-4],[\"MU\",2.0E-4],[\"MM\",2.0E-4],[\"MT\",2.0E-4],[\"NA\",2.0E-4],[\"IS\",2.0E-4],[\"KH\",2.0E-4],[\"DJ\",1.0E-4],[\"UG\",1.0E-4],[\"TZ\",1.0E-4],[\"GY\",1.0E-4],[\"GU\",1.0E-4],[\"GP\",1.0E-4],[\"RE\",1.0E-4],[\"AM\",1.0E-4],[\"TG\",1.0E-4],[\"BS\",1.0E-4],[\"BB\",1.0E-4],[\"BN\",1.0E-4],[\"BJ\",1.0E-4],[\"CW\",1.0E-4],[\"CD\",1.0E-4],[\"CM\",1.0E-4],[\"ME\",1.0E-4],[\"MV\",1.0E-4],[\"MZ\",1.0E-4],[\"MO\",1.0E-4],[\"MQ\",1.0E-4],[\"NI\",1.0E-4],[\"NE\",1.0E-4],[\"HT\",1.0E-4],[\"ZM\",1.0E-4],[\"ZW\",1.0E-4],[\"JE\",1.0E-4],[\"KG\",1.0E-4],[\"KY\",1.0E-4],[\"LA\",1.0E-4]],\"geodiversity_normalized\":[[\"BM\",0.20375896159233017],[\"YE\",0.09244116857647527],[\"LY\",0.03906714839945628],[\"JP\",0.030247161175715482],[\"UY\",0.017327997941008564],[\"GP\",0.01611794734153928],[\"OM\",0.01584445948550431],[\"UZ\",0.012655753260989624],[\"ZA\",0.012459173513181756],[\"NA\",0.012353255907166424],[\"DJ\",0.012059048193487418],[\"ET\",0.011267448269447748],[\"NE\",0.011130948345478668],[\"TG\",0.011115586042923016],[\"MQ\",0.010917816571685718],[\"CD\",0.010133128017268738],[\"IR\",0.009554115786249174],[\"GY\",0.009020860272706092],[\"ZW\",0.008999440533249985],[\"JO\",0.008587359427940694],[\"CI\",0.008458906984088651],[\"EC\",0.008424890295545056],[\"ZM\",0.008062503221898677],[\"QA\",0.007927753403880314],[\"MA\",0.007834061862256707],[\"SD\",0.007603882043760343],[\"SA\",0.007515213996104046],[\"IL\",0.007413411654412088],[\"NP\",0.0073149722224984315],[\"LB\",0.006992890545058264],[\"PH\",0.006975493060458157],[\"TT\",0.006877277598164459],[\"MM\",0.00672071497838774],[\"NZ\",0.006606545844889045],[\"AU\",0.006420955278274985],[\"SN\",0.005953888649969115],[\"GU\",0.005444608289488192],[\"PY\",0.005383647601754953],[\"BJ\",0.005373769349274668],[\"AM\",0.005345902883036986],[\"ME\",0.0051186887386536865],[\"IN\",0.005105527493742024],[\"LK\",0.005030075492148507],[\"BZ\",0.005025008344752182],[\"MU\",0.004938319913989788],[\"SG\",0.004904747993133913],[\"BH\",0.0048228971516750836],[\"KW\",0.004798889830765654],[\"EG\",0.004619340709342588],[\"BR\",0.004599468222743493],[\"AT\",0.004540410833015574],[\"GH\",0.004520279187084444],[\"HU\",0.0045116381878804275],[\"GE\",0.004497835567036878],[\"KE\",0.004491586986786001],[\"AE\",0.004484969188213879],[\"MT\",0.004350760132876633],[\"CO\",0.0043249507554260005],[\"PT\",0.0043077022802489266],[\"MD\",0.00428657404682345],[\"MZ\",0.004127445917671008],[\"TN\",0.0038572622599467817],[\"BD\",0.0038168055504889087],[\"PE\",0.003802764959897941],[\"GT\",0.0037809849520660166],[\"BO\",0.0037776439081732686],[\"RE\",0.0037705696686448544],[\"IS\",0.0037224273209199416],[\"CZ\",0.0037113614866476213],[\"SY\",0.003700792682319089],[\"MO\",0.0036077884818748684],[\"ES\",0.0035846536395296663],[\"MX\",0.0035827810660169703],[\"BW\",0.0035818656343892972],[\"CL\",0.003554849247808106],[\"DE\",0.003531979589799978],[\"GR\",0.003524631758147203],[\"IQ\",0.0034449203973161615],[\"HK\",0.0034358080966143713],[\"KG\",0.0032849747373204486],[\"JE\",0.003256006998903569],[\"HR\",0.0032409882444745662],[\"VE\",0.0032242854277104603],[\"SV\",0.0031234464489522467],[\"KR\",0.003049835621805406],[\"AF\",0.003036249637633131],[\"RO\",0.002997571804394868],[\"CH\",0.002979705709246971],[\"KZ\",0.0029703044415169007],[\"BE\",0.0029144025985733658],[\"MV\",0.0028368296972065285],[\"CR\",0.002776258271107416],[\"BB\",0.0027733942190858846],[\"AZ\",0.0027669033344557264],[\"LT\",0.0027166143334635736],[\"FR\",0.002678444359267468],[\"KY\",0.002611575887068207],[\"HN\",0.002598002229714169],[\"FI\",0.002592164727092915],[\"KH\",0.0025637233207784207],[\"SE\",0.002559739783173962],[\"HT\",0.0025571097550423963],[\"US\",0.0024955430120255106],[\"UG\",0.0024637310529903363],[\"DO\",0.002447096492825564],[\"PA\",0.0024279688323486756],[\"NL\",0.0023297394861225263],[\"EE\",0.002320455022564876],[\"IE\",0.0023053956285744802],[\"SI\",0.002304148999054233],[\"RS\",0.0022736983175376756],[\"PS\",0.002254662648206714],[\"TW\",0.002188166300297028],[\"TZ\",0.0021626386902226457],[\"AO\",0.0021310410867562417],[\"SK\",0.0019483833374038515],[\"CA\",0.0019178395715433397],[\"BY\",0.0019097823579033273],[\"MY\",0.0018519651455630832],[\"AL\",0.0018296669943540411],[\"AR\",0.001817066969918926],[\"GB\",0.001795893396906611],[\"CY\",0.0017925147482679188],[\"LA\",0.0017850531790498205],[\"TH\",0.0017688191331781708],[\"LV\",0.0017597982819709738],[\"PL\",0.0017570479059798101],[\"JM\",0.0017179364931356996],[\"NO\",0.0016701570504380208],[\"LU\",0.0015553395089509797],[\"IT\",0.0014440301311380746],[\"NG\",0.0013904044024260944],[\"UA\",0.0013449056884677643],[\"BA\",0.0012723618350648786],[\"MK\",0.0012578380153405292],[\"??\",0.00124098909424614],[\"BS\",0.0011379132764855538],[\"PR\",0.0011252738806954998],[\"VN\",0.0011050924675411258],[\"PK\",0.0010718205066905487],[\"RU\",0.0010681750932449397],[\"ID\",9.676335777603613E-4],[\"BG\",9.381747224025812E-4],[\"CN\",8.529633575726018E-4],[\"DK\",8.518203079498652E-4],[\"CW\",7.487854976037012E-4],[\"DZ\",6.800142031102517E-4],[\"TR\",5.295034276648443E-4],[\"CM\",3.475859949117745E-4],[\"BN\",3.384718139199583E-4],[\"NI\",2.8908538206708653E-4]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"

    #domain_list = "{\"recordInfo\":{\"totalMaliciousDomain\":2},\"features\":{\"rr_count\":95}}"
    domain_list = "{\"recordInfo\":{\"totalMaliciousDomain\":2},\"features\":{\"rr_count\":105},\"records\":[{\"rr\":\"abc.com\"},{\"rr\":\"abc1.com\"}]}"
    expect(Virustotal::Scan).to receive(:scan_hashes).and_return(virus_total_conviction_hash).at_least(:once)
    expect(RepApi::Whitelist).to receive(:get_whitelist_info).and_raise(RepApi::RepApiNotFoundError, "HTTP response 404").at_least(:once)
    expect(Umbrella::SecurityInfo).to receive(:query_malicious_domains).and_return(domain_list).at_least(:once)
    expect(Umbrella::Scan).to receive(:scan_result).with(address: "1.2.3.4").and_return(umbrella_scan_good).at_least(:once)

    #expect(Umbrella::SecurityInfo).to receive(:query_info).and_return(@umbrella_popular_bad).at_least(:once)

    expect(AutoResolve).to receive(:commit_to_reptool).and_return({:success => true}).at_least(:once)
    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: no_rules_ip_auto_resolve_json_allow

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    expect(dispute.dispute_entries.where(uri: '1.2.3.4')).to exist


    dispute_entry_1 = DisputeEntry.where(:uri => '1.2.3.4').first

    expect(dispute_entry_1.status).to eql("RESOLVED_CLOSED")
    expect(dispute_entry_1.resolution).to eql("AP - FN")
    expect(dispute_entry_1.resolution_comment).to eql("Talos has lowered our reputation score for the URL/Domain/Host to block access.")

    expect(dispute_entry_1.auto_resolve_category).to eql("Trusted/High Count VT hit(s)/high domain count")
  end

  it 'should auto resolve if malicious domains >= 70%' do

    umbrella_scan_good = UmbrellaScanResponse.new
    umbrella_scan_good.code = 200
    umbrella_scan_good.body = "{\"google.com\":{\"status\":1,\"security_categories\":[],\"content_categories\":[\"23\"]}}"

    @umbrella_popular_bad = UmbrellaSecurityInfoResponse.new
    @umbrella_popular_bad.code = 200
    @umbrella_popular_bad.body = "{\"dga_score\":0.0,\"perplexity\":0.1698321879522074,\"entropy\":3.4594316186372978,\"securerank2\":0.0,\"pagerank\":0.0,\"asn_score\":-0.014739406284196042,\"prefix_score\":-0.023982712069696013,\"rip_score\":-0.011198019721606252,\"popularity\":0.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.5],[\"BR\",0.5]],\"geodiversity_normalized\":[[\"BR\",0.863526213328589],[\"US\",0.13647378667141086]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"


    umbrella_popular_good = UmbrellaSecurityInfoResponse.new
    umbrella_popular_good.code = 200
    umbrella_popular_good.body = "{\"dga_score\":0.0,\"perplexity\":0.18786756104373362,\"entropy\":1.9182958340544896,\"securerank2\":100.0,\"pagerank\":63.36242,\"asn_score\":-0.07587332170749107,\"prefix_score\":-0.02867604643567799,\"rip_score\":-0.12451293522019732,\"popularity\":100.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.3591],[\"BR\",0.1046],[\"IN\",0.0603],[\"CA\",0.0358],[\"GB\",0.0344],[\"EG\",0.0288],[\"TR\",0.0216],[\"VN\",0.0202],[\"IT\",0.02],[\"MX\",0.0169],[\"DE\",0.0162],[\"FR\",0.0152],[\"AU\",0.0138],[\"JP\",0.0129],[\"PH\",0.0126],[\"RU\",0.0113],[\"ES\",0.0106],[\"IR\",0.0098],[\"NL\",0.0085],[\"PL\",0.0085],[\"ID\",0.0072],[\"CN\",0.0071],[\"AR\",0.007],[\"MY\",0.007],[\"UA\",0.0068],[\"DZ\",0.0064],[\"CO\",0.0056],[\"EC\",0.0053],[\"ZA\",0.005],[\"PT\",0.0047],[\"SE\",0.0045],[\"SA\",0.0039],[\"TH\",0.0038],[\"BE\",0.0037],[\"SG\",0.0036],[\"CL\",0.0036],[\"VE\",0.0035],[\"DK\",0.0033],[\"PE\",0.0032],[\"MA\",0.0031],[\"IE\",0.0031],[\"IL\",0.0029],[\"YE\",0.0027],[\"CH\",0.0026],[\"RO\",0.0024],[\"HK\",0.0024],[\"GR\",0.0023],[\"CZ\",0.0023],[\"TW\",0.0021],[\"AE\",0.0021],[\"PK\",0.0021],[\"AT\",0.002],[\"NZ\",0.002],[\"HU\",0.002],[\"NO\",0.0019],[\"KZ\",0.0017],[\"??\",0.0016],[\"AF\",0.0016],[\"KR\",0.0016],[\"CR\",0.0015],[\"IQ\",0.0015],[\"BM\",0.0014],[\"UY\",0.0013],[\"SK\",0.0012],[\"DO\",0.0011],[\"TT\",0.001],[\"BG\",0.001],[\"BD\",0.001],[\"LK\",0.001],[\"BY\",9.0E-4],[\"TN\",9.0E-4],[\"NG\",9.0E-4],[\"FI\",8.0E-4],[\"PR\",8.0E-4],[\"SY\",8.0E-4],[\"RS\",8.0E-4],[\"JO\",8.0E-4],[\"GT\",7.0E-4],[\"BA\",7.0E-4],[\"BO\",7.0E-4],[\"LT\",7.0E-4],[\"KE\",7.0E-4],[\"LB\",7.0E-4],[\"UZ\",6.0E-4],[\"QA\",6.0E-4],[\"SD\",6.0E-4],[\"LY\",6.0E-4],[\"NP\",6.0E-4],[\"OM\",5.0E-4],[\"PA\",5.0E-4],[\"HN\",5.0E-4],[\"HR\",5.0E-4],[\"ET\",4.0E-4],[\"GH\",4.0E-4],[\"AZ\",4.0E-4],[\"PS\",4.0E-4],[\"AL\",4.0E-4],[\"PY\",4.0E-4],[\"SI\",4.0E-4],[\"BZ\",3.0E-4],[\"SV\",3.0E-4],[\"CI\",3.0E-4],[\"JM\",3.0E-4],[\"KW\",3.0E-4],[\"EE\",2.0E-4],[\"GE\",2.0E-4],[\"AO\",2.0E-4],[\"BW\",2.0E-4],[\"BH\",2.0E-4],[\"CY\",2.0E-4],[\"SN\",2.0E-4],[\"LV\",2.0E-4],[\"LU\",2.0E-4],[\"MK\",2.0E-4],[\"MD\",2.0E-4],[\"MU\",2.0E-4],[\"MM\",2.0E-4],[\"MT\",2.0E-4],[\"NA\",2.0E-4],[\"IS\",2.0E-4],[\"KH\",2.0E-4],[\"DJ\",1.0E-4],[\"UG\",1.0E-4],[\"TZ\",1.0E-4],[\"GY\",1.0E-4],[\"GU\",1.0E-4],[\"GP\",1.0E-4],[\"RE\",1.0E-4],[\"AM\",1.0E-4],[\"TG\",1.0E-4],[\"BS\",1.0E-4],[\"BB\",1.0E-4],[\"BN\",1.0E-4],[\"BJ\",1.0E-4],[\"CW\",1.0E-4],[\"CD\",1.0E-4],[\"CM\",1.0E-4],[\"ME\",1.0E-4],[\"MV\",1.0E-4],[\"MZ\",1.0E-4],[\"MO\",1.0E-4],[\"MQ\",1.0E-4],[\"NI\",1.0E-4],[\"NE\",1.0E-4],[\"HT\",1.0E-4],[\"ZM\",1.0E-4],[\"ZW\",1.0E-4],[\"JE\",1.0E-4],[\"KG\",1.0E-4],[\"KY\",1.0E-4],[\"LA\",1.0E-4]],\"geodiversity_normalized\":[[\"BM\",0.20375896159233017],[\"YE\",0.09244116857647527],[\"LY\",0.03906714839945628],[\"JP\",0.030247161175715482],[\"UY\",0.017327997941008564],[\"GP\",0.01611794734153928],[\"OM\",0.01584445948550431],[\"UZ\",0.012655753260989624],[\"ZA\",0.012459173513181756],[\"NA\",0.012353255907166424],[\"DJ\",0.012059048193487418],[\"ET\",0.011267448269447748],[\"NE\",0.011130948345478668],[\"TG\",0.011115586042923016],[\"MQ\",0.010917816571685718],[\"CD\",0.010133128017268738],[\"IR\",0.009554115786249174],[\"GY\",0.009020860272706092],[\"ZW\",0.008999440533249985],[\"JO\",0.008587359427940694],[\"CI\",0.008458906984088651],[\"EC\",0.008424890295545056],[\"ZM\",0.008062503221898677],[\"QA\",0.007927753403880314],[\"MA\",0.007834061862256707],[\"SD\",0.007603882043760343],[\"SA\",0.007515213996104046],[\"IL\",0.007413411654412088],[\"NP\",0.0073149722224984315],[\"LB\",0.006992890545058264],[\"PH\",0.006975493060458157],[\"TT\",0.006877277598164459],[\"MM\",0.00672071497838774],[\"NZ\",0.006606545844889045],[\"AU\",0.006420955278274985],[\"SN\",0.005953888649969115],[\"GU\",0.005444608289488192],[\"PY\",0.005383647601754953],[\"BJ\",0.005373769349274668],[\"AM\",0.005345902883036986],[\"ME\",0.0051186887386536865],[\"IN\",0.005105527493742024],[\"LK\",0.005030075492148507],[\"BZ\",0.005025008344752182],[\"MU\",0.004938319913989788],[\"SG\",0.004904747993133913],[\"BH\",0.0048228971516750836],[\"KW\",0.004798889830765654],[\"EG\",0.004619340709342588],[\"BR\",0.004599468222743493],[\"AT\",0.004540410833015574],[\"GH\",0.004520279187084444],[\"HU\",0.0045116381878804275],[\"GE\",0.004497835567036878],[\"KE\",0.004491586986786001],[\"AE\",0.004484969188213879],[\"MT\",0.004350760132876633],[\"CO\",0.0043249507554260005],[\"PT\",0.0043077022802489266],[\"MD\",0.00428657404682345],[\"MZ\",0.004127445917671008],[\"TN\",0.0038572622599467817],[\"BD\",0.0038168055504889087],[\"PE\",0.003802764959897941],[\"GT\",0.0037809849520660166],[\"BO\",0.0037776439081732686],[\"RE\",0.0037705696686448544],[\"IS\",0.0037224273209199416],[\"CZ\",0.0037113614866476213],[\"SY\",0.003700792682319089],[\"MO\",0.0036077884818748684],[\"ES\",0.0035846536395296663],[\"MX\",0.0035827810660169703],[\"BW\",0.0035818656343892972],[\"CL\",0.003554849247808106],[\"DE\",0.003531979589799978],[\"GR\",0.003524631758147203],[\"IQ\",0.0034449203973161615],[\"HK\",0.0034358080966143713],[\"KG\",0.0032849747373204486],[\"JE\",0.003256006998903569],[\"HR\",0.0032409882444745662],[\"VE\",0.0032242854277104603],[\"SV\",0.0031234464489522467],[\"KR\",0.003049835621805406],[\"AF\",0.003036249637633131],[\"RO\",0.002997571804394868],[\"CH\",0.002979705709246971],[\"KZ\",0.0029703044415169007],[\"BE\",0.0029144025985733658],[\"MV\",0.0028368296972065285],[\"CR\",0.002776258271107416],[\"BB\",0.0027733942190858846],[\"AZ\",0.0027669033344557264],[\"LT\",0.0027166143334635736],[\"FR\",0.002678444359267468],[\"KY\",0.002611575887068207],[\"HN\",0.002598002229714169],[\"FI\",0.002592164727092915],[\"KH\",0.0025637233207784207],[\"SE\",0.002559739783173962],[\"HT\",0.0025571097550423963],[\"US\",0.0024955430120255106],[\"UG\",0.0024637310529903363],[\"DO\",0.002447096492825564],[\"PA\",0.0024279688323486756],[\"NL\",0.0023297394861225263],[\"EE\",0.002320455022564876],[\"IE\",0.0023053956285744802],[\"SI\",0.002304148999054233],[\"RS\",0.0022736983175376756],[\"PS\",0.002254662648206714],[\"TW\",0.002188166300297028],[\"TZ\",0.0021626386902226457],[\"AO\",0.0021310410867562417],[\"SK\",0.0019483833374038515],[\"CA\",0.0019178395715433397],[\"BY\",0.0019097823579033273],[\"MY\",0.0018519651455630832],[\"AL\",0.0018296669943540411],[\"AR\",0.001817066969918926],[\"GB\",0.001795893396906611],[\"CY\",0.0017925147482679188],[\"LA\",0.0017850531790498205],[\"TH\",0.0017688191331781708],[\"LV\",0.0017597982819709738],[\"PL\",0.0017570479059798101],[\"JM\",0.0017179364931356996],[\"NO\",0.0016701570504380208],[\"LU\",0.0015553395089509797],[\"IT\",0.0014440301311380746],[\"NG\",0.0013904044024260944],[\"UA\",0.0013449056884677643],[\"BA\",0.0012723618350648786],[\"MK\",0.0012578380153405292],[\"??\",0.00124098909424614],[\"BS\",0.0011379132764855538],[\"PR\",0.0011252738806954998],[\"VN\",0.0011050924675411258],[\"PK\",0.0010718205066905487],[\"RU\",0.0010681750932449397],[\"ID\",9.676335777603613E-4],[\"BG\",9.381747224025812E-4],[\"CN\",8.529633575726018E-4],[\"DK\",8.518203079498652E-4],[\"CW\",7.487854976037012E-4],[\"DZ\",6.800142031102517E-4],[\"TR\",5.295034276648443E-4],[\"CM\",3.475859949117745E-4],[\"BN\",3.384718139199583E-4],[\"NI\",2.8908538206708653E-4]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"

    #domain_list = "{\"recordInfo\":{\"totalMaliciousDomain\":2},\"features\":{\"rr_count\":95}}"
    domain_list = "{\"recordInfo\":{\"totalMaliciousDomain\":95},\"features\":{\"rr_count\":105},\"records\":[{\"rr\":\"abc.com\"},{\"rr\":\"abc1.com\"}]}"
    expect(Virustotal::Scan).to receive(:scan_hashes).and_return(virus_total_nonconviction_hash).at_least(:once)
    expect(RepApi::Whitelist).to receive(:get_whitelist_info).and_raise(RepApi::RepApiNotFoundError, "HTTP response 404").at_least(:once)
    expect(Umbrella::SecurityInfo).to receive(:query_malicious_domains).and_return(domain_list).at_least(:once)
    #expect(Umbrella::Scan).to receive(:scan_result).with(address: "1.2.3.4").and_return(umbrella_scan_good).at_least(:once)

    #expect(Umbrella::SecurityInfo).to receive(:query_info).and_return(@umbrella_popular_bad).at_least(:once)

    expect(AutoResolve).to receive(:commit_to_reptool).and_return({:success => true}).at_least(:once)
    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: no_rules_ip_auto_resolve_json_allow

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    expect(dispute.dispute_entries.where(uri: '1.2.3.4')).to exist


    dispute_entry_1 = DisputeEntry.where(:uri => '1.2.3.4').first

    expect(dispute_entry_1.status).to eql("RESOLVED_CLOSED")
    expect(dispute_entry_1.resolution).to eql("AP - FN")
    expect(dispute_entry_1.resolution_comment).to eql("Talos has lowered our reputation score for the URL/Domain/Host to block access.")

    expect(dispute_entry_1.auto_resolve_category).to eql("70% malicious ratio/high domain count")

  end

  ###############

  it 'should auto resolve if hosted domains < 100, highest popularity < 40, vt hits >= 3' do

    umbrella_scan_good = UmbrellaScanResponse.new
    umbrella_scan_good.code = 200
    umbrella_scan_good.body = "{\"google.com\":{\"status\":1,\"security_categories\":[],\"content_categories\":[\"23\"]}}"

    @umbrella_popular_bad = UmbrellaSecurityInfoResponse.new
    @umbrella_popular_bad.code = 200
    @umbrella_popular_bad.body = "{\"dga_score\":0.0,\"perplexity\":0.1698321879522074,\"entropy\":3.4594316186372978,\"securerank2\":0.0,\"pagerank\":0.0,\"asn_score\":-0.014739406284196042,\"prefix_score\":-0.023982712069696013,\"rip_score\":-0.011198019721606252,\"popularity\":0.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.5],[\"BR\",0.5]],\"geodiversity_normalized\":[[\"BR\",0.863526213328589],[\"US\",0.13647378667141086]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"


    umbrella_popular_good = UmbrellaSecurityInfoResponse.new
    umbrella_popular_good.code = 200
    umbrella_popular_good.body = "{\"dga_score\":0.0,\"perplexity\":0.18786756104373362,\"entropy\":1.9182958340544896,\"securerank2\":100.0,\"pagerank\":63.36242,\"asn_score\":-0.07587332170749107,\"prefix_score\":-0.02867604643567799,\"rip_score\":-0.12451293522019732,\"popularity\":100.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.3591],[\"BR\",0.1046],[\"IN\",0.0603],[\"CA\",0.0358],[\"GB\",0.0344],[\"EG\",0.0288],[\"TR\",0.0216],[\"VN\",0.0202],[\"IT\",0.02],[\"MX\",0.0169],[\"DE\",0.0162],[\"FR\",0.0152],[\"AU\",0.0138],[\"JP\",0.0129],[\"PH\",0.0126],[\"RU\",0.0113],[\"ES\",0.0106],[\"IR\",0.0098],[\"NL\",0.0085],[\"PL\",0.0085],[\"ID\",0.0072],[\"CN\",0.0071],[\"AR\",0.007],[\"MY\",0.007],[\"UA\",0.0068],[\"DZ\",0.0064],[\"CO\",0.0056],[\"EC\",0.0053],[\"ZA\",0.005],[\"PT\",0.0047],[\"SE\",0.0045],[\"SA\",0.0039],[\"TH\",0.0038],[\"BE\",0.0037],[\"SG\",0.0036],[\"CL\",0.0036],[\"VE\",0.0035],[\"DK\",0.0033],[\"PE\",0.0032],[\"MA\",0.0031],[\"IE\",0.0031],[\"IL\",0.0029],[\"YE\",0.0027],[\"CH\",0.0026],[\"RO\",0.0024],[\"HK\",0.0024],[\"GR\",0.0023],[\"CZ\",0.0023],[\"TW\",0.0021],[\"AE\",0.0021],[\"PK\",0.0021],[\"AT\",0.002],[\"NZ\",0.002],[\"HU\",0.002],[\"NO\",0.0019],[\"KZ\",0.0017],[\"??\",0.0016],[\"AF\",0.0016],[\"KR\",0.0016],[\"CR\",0.0015],[\"IQ\",0.0015],[\"BM\",0.0014],[\"UY\",0.0013],[\"SK\",0.0012],[\"DO\",0.0011],[\"TT\",0.001],[\"BG\",0.001],[\"BD\",0.001],[\"LK\",0.001],[\"BY\",9.0E-4],[\"TN\",9.0E-4],[\"NG\",9.0E-4],[\"FI\",8.0E-4],[\"PR\",8.0E-4],[\"SY\",8.0E-4],[\"RS\",8.0E-4],[\"JO\",8.0E-4],[\"GT\",7.0E-4],[\"BA\",7.0E-4],[\"BO\",7.0E-4],[\"LT\",7.0E-4],[\"KE\",7.0E-4],[\"LB\",7.0E-4],[\"UZ\",6.0E-4],[\"QA\",6.0E-4],[\"SD\",6.0E-4],[\"LY\",6.0E-4],[\"NP\",6.0E-4],[\"OM\",5.0E-4],[\"PA\",5.0E-4],[\"HN\",5.0E-4],[\"HR\",5.0E-4],[\"ET\",4.0E-4],[\"GH\",4.0E-4],[\"AZ\",4.0E-4],[\"PS\",4.0E-4],[\"AL\",4.0E-4],[\"PY\",4.0E-4],[\"SI\",4.0E-4],[\"BZ\",3.0E-4],[\"SV\",3.0E-4],[\"CI\",3.0E-4],[\"JM\",3.0E-4],[\"KW\",3.0E-4],[\"EE\",2.0E-4],[\"GE\",2.0E-4],[\"AO\",2.0E-4],[\"BW\",2.0E-4],[\"BH\",2.0E-4],[\"CY\",2.0E-4],[\"SN\",2.0E-4],[\"LV\",2.0E-4],[\"LU\",2.0E-4],[\"MK\",2.0E-4],[\"MD\",2.0E-4],[\"MU\",2.0E-4],[\"MM\",2.0E-4],[\"MT\",2.0E-4],[\"NA\",2.0E-4],[\"IS\",2.0E-4],[\"KH\",2.0E-4],[\"DJ\",1.0E-4],[\"UG\",1.0E-4],[\"TZ\",1.0E-4],[\"GY\",1.0E-4],[\"GU\",1.0E-4],[\"GP\",1.0E-4],[\"RE\",1.0E-4],[\"AM\",1.0E-4],[\"TG\",1.0E-4],[\"BS\",1.0E-4],[\"BB\",1.0E-4],[\"BN\",1.0E-4],[\"BJ\",1.0E-4],[\"CW\",1.0E-4],[\"CD\",1.0E-4],[\"CM\",1.0E-4],[\"ME\",1.0E-4],[\"MV\",1.0E-4],[\"MZ\",1.0E-4],[\"MO\",1.0E-4],[\"MQ\",1.0E-4],[\"NI\",1.0E-4],[\"NE\",1.0E-4],[\"HT\",1.0E-4],[\"ZM\",1.0E-4],[\"ZW\",1.0E-4],[\"JE\",1.0E-4],[\"KG\",1.0E-4],[\"KY\",1.0E-4],[\"LA\",1.0E-4]],\"geodiversity_normalized\":[[\"BM\",0.20375896159233017],[\"YE\",0.09244116857647527],[\"LY\",0.03906714839945628],[\"JP\",0.030247161175715482],[\"UY\",0.017327997941008564],[\"GP\",0.01611794734153928],[\"OM\",0.01584445948550431],[\"UZ\",0.012655753260989624],[\"ZA\",0.012459173513181756],[\"NA\",0.012353255907166424],[\"DJ\",0.012059048193487418],[\"ET\",0.011267448269447748],[\"NE\",0.011130948345478668],[\"TG\",0.011115586042923016],[\"MQ\",0.010917816571685718],[\"CD\",0.010133128017268738],[\"IR\",0.009554115786249174],[\"GY\",0.009020860272706092],[\"ZW\",0.008999440533249985],[\"JO\",0.008587359427940694],[\"CI\",0.008458906984088651],[\"EC\",0.008424890295545056],[\"ZM\",0.008062503221898677],[\"QA\",0.007927753403880314],[\"MA\",0.007834061862256707],[\"SD\",0.007603882043760343],[\"SA\",0.007515213996104046],[\"IL\",0.007413411654412088],[\"NP\",0.0073149722224984315],[\"LB\",0.006992890545058264],[\"PH\",0.006975493060458157],[\"TT\",0.006877277598164459],[\"MM\",0.00672071497838774],[\"NZ\",0.006606545844889045],[\"AU\",0.006420955278274985],[\"SN\",0.005953888649969115],[\"GU\",0.005444608289488192],[\"PY\",0.005383647601754953],[\"BJ\",0.005373769349274668],[\"AM\",0.005345902883036986],[\"ME\",0.0051186887386536865],[\"IN\",0.005105527493742024],[\"LK\",0.005030075492148507],[\"BZ\",0.005025008344752182],[\"MU\",0.004938319913989788],[\"SG\",0.004904747993133913],[\"BH\",0.0048228971516750836],[\"KW\",0.004798889830765654],[\"EG\",0.004619340709342588],[\"BR\",0.004599468222743493],[\"AT\",0.004540410833015574],[\"GH\",0.004520279187084444],[\"HU\",0.0045116381878804275],[\"GE\",0.004497835567036878],[\"KE\",0.004491586986786001],[\"AE\",0.004484969188213879],[\"MT\",0.004350760132876633],[\"CO\",0.0043249507554260005],[\"PT\",0.0043077022802489266],[\"MD\",0.00428657404682345],[\"MZ\",0.004127445917671008],[\"TN\",0.0038572622599467817],[\"BD\",0.0038168055504889087],[\"PE\",0.003802764959897941],[\"GT\",0.0037809849520660166],[\"BO\",0.0037776439081732686],[\"RE\",0.0037705696686448544],[\"IS\",0.0037224273209199416],[\"CZ\",0.0037113614866476213],[\"SY\",0.003700792682319089],[\"MO\",0.0036077884818748684],[\"ES\",0.0035846536395296663],[\"MX\",0.0035827810660169703],[\"BW\",0.0035818656343892972],[\"CL\",0.003554849247808106],[\"DE\",0.003531979589799978],[\"GR\",0.003524631758147203],[\"IQ\",0.0034449203973161615],[\"HK\",0.0034358080966143713],[\"KG\",0.0032849747373204486],[\"JE\",0.003256006998903569],[\"HR\",0.0032409882444745662],[\"VE\",0.0032242854277104603],[\"SV\",0.0031234464489522467],[\"KR\",0.003049835621805406],[\"AF\",0.003036249637633131],[\"RO\",0.002997571804394868],[\"CH\",0.002979705709246971],[\"KZ\",0.0029703044415169007],[\"BE\",0.0029144025985733658],[\"MV\",0.0028368296972065285],[\"CR\",0.002776258271107416],[\"BB\",0.0027733942190858846],[\"AZ\",0.0027669033344557264],[\"LT\",0.0027166143334635736],[\"FR\",0.002678444359267468],[\"KY\",0.002611575887068207],[\"HN\",0.002598002229714169],[\"FI\",0.002592164727092915],[\"KH\",0.0025637233207784207],[\"SE\",0.002559739783173962],[\"HT\",0.0025571097550423963],[\"US\",0.0024955430120255106],[\"UG\",0.0024637310529903363],[\"DO\",0.002447096492825564],[\"PA\",0.0024279688323486756],[\"NL\",0.0023297394861225263],[\"EE\",0.002320455022564876],[\"IE\",0.0023053956285744802],[\"SI\",0.002304148999054233],[\"RS\",0.0022736983175376756],[\"PS\",0.002254662648206714],[\"TW\",0.002188166300297028],[\"TZ\",0.0021626386902226457],[\"AO\",0.0021310410867562417],[\"SK\",0.0019483833374038515],[\"CA\",0.0019178395715433397],[\"BY\",0.0019097823579033273],[\"MY\",0.0018519651455630832],[\"AL\",0.0018296669943540411],[\"AR\",0.001817066969918926],[\"GB\",0.001795893396906611],[\"CY\",0.0017925147482679188],[\"LA\",0.0017850531790498205],[\"TH\",0.0017688191331781708],[\"LV\",0.0017597982819709738],[\"PL\",0.0017570479059798101],[\"JM\",0.0017179364931356996],[\"NO\",0.0016701570504380208],[\"LU\",0.0015553395089509797],[\"IT\",0.0014440301311380746],[\"NG\",0.0013904044024260944],[\"UA\",0.0013449056884677643],[\"BA\",0.0012723618350648786],[\"MK\",0.0012578380153405292],[\"??\",0.00124098909424614],[\"BS\",0.0011379132764855538],[\"PR\",0.0011252738806954998],[\"VN\",0.0011050924675411258],[\"PK\",0.0010718205066905487],[\"RU\",0.0010681750932449397],[\"ID\",9.676335777603613E-4],[\"BG\",9.381747224025812E-4],[\"CN\",8.529633575726018E-4],[\"DK\",8.518203079498652E-4],[\"CW\",7.487854976037012E-4],[\"DZ\",6.800142031102517E-4],[\"TR\",5.295034276648443E-4],[\"CM\",3.475859949117745E-4],[\"BN\",3.384718139199583E-4],[\"NI\",2.8908538206708653E-4]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"

    #domain_list = "{\"recordInfo\":{\"totalMaliciousDomain\":2},\"features\":{\"rr_count\":95}}"
    domain_list = "{\"recordInfo\":{\"totalMaliciousDomain\":5},\"features\":{\"rr_count\":55},\"records\":[{\"rr\":\"abc.com\"},{\"rr\":\"abc1.com\"}]}"
    expect(Virustotal::Scan).to receive(:scan_hashes).and_return(virus_total_conviction_hash).at_least(:once)
    expect(RepApi::Whitelist).to receive(:get_whitelist_info).and_raise(RepApi::RepApiNotFoundError, "HTTP response 404").at_least(:once)
    expect(Umbrella::SecurityInfo).to receive(:query_malicious_domains).and_return(domain_list).at_least(:once)
    #expect(Umbrella::Scan).to receive(:scan_result).with(address: "1.2.3.4").and_return(umbrella_scan_good).at_least(:once)

    expect(Umbrella::SecurityInfo).to receive(:query_info).and_return(@umbrella_popular_bad).at_least(:once)

    expect(AutoResolve).to receive(:commit_to_reptool).and_return({:success => true}).at_least(:once)
    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: no_rules_ip_auto_resolve_json_allow

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    expect(dispute.dispute_entries.where(uri: '1.2.3.4')).to exist


    dispute_entry_1 = DisputeEntry.where(:uri => '1.2.3.4').first

    expect(dispute_entry_1.status).to eql("RESOLVED_CLOSED")
    expect(dispute_entry_1.resolution).to eql("AP - FN")
    expect(dispute_entry_1.resolution_comment).to eql("Talos has lowered our reputation score for the URL/Domain/Host to block access.")

    expect(dispute_entry_1.auto_resolve_category).to eql("Trusted/High Count VT hit(s)/low domain count")
  end

  it 'should auto resolve if hosted domains < 100, highest popularity < 40, asn on block list' do


    umbrella_scan_good = UmbrellaScanResponse.new
    umbrella_scan_good.code = 200
    umbrella_scan_good.body = "{\"google.com\":{\"status\":1,\"security_categories\":[],\"content_categories\":[\"23\"]}}"

    @umbrella_popular_bad = UmbrellaSecurityInfoResponse.new
    @umbrella_popular_bad.code = 200
    @umbrella_popular_bad.body = "{\"dga_score\":0.0,\"perplexity\":0.1698321879522074,\"entropy\":3.4594316186372978,\"securerank2\":0.0,\"pagerank\":0.0,\"asn_score\":-0.014739406284196042,\"prefix_score\":-0.023982712069696013,\"rip_score\":-0.011198019721606252,\"popularity\":0.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.5],[\"BR\",0.5]],\"geodiversity_normalized\":[[\"BR\",0.863526213328589],[\"US\",0.13647378667141086]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"


    umbrella_popular_good = UmbrellaSecurityInfoResponse.new
    umbrella_popular_good.code = 200
    umbrella_popular_good.body = "{\"dga_score\":0.0,\"perplexity\":0.18786756104373362,\"entropy\":1.9182958340544896,\"securerank2\":100.0,\"pagerank\":63.36242,\"asn_score\":-0.07587332170749107,\"prefix_score\":-0.02867604643567799,\"rip_score\":-0.12451293522019732,\"popularity\":100.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.3591],[\"BR\",0.1046],[\"IN\",0.0603],[\"CA\",0.0358],[\"GB\",0.0344],[\"EG\",0.0288],[\"TR\",0.0216],[\"VN\",0.0202],[\"IT\",0.02],[\"MX\",0.0169],[\"DE\",0.0162],[\"FR\",0.0152],[\"AU\",0.0138],[\"JP\",0.0129],[\"PH\",0.0126],[\"RU\",0.0113],[\"ES\",0.0106],[\"IR\",0.0098],[\"NL\",0.0085],[\"PL\",0.0085],[\"ID\",0.0072],[\"CN\",0.0071],[\"AR\",0.007],[\"MY\",0.007],[\"UA\",0.0068],[\"DZ\",0.0064],[\"CO\",0.0056],[\"EC\",0.0053],[\"ZA\",0.005],[\"PT\",0.0047],[\"SE\",0.0045],[\"SA\",0.0039],[\"TH\",0.0038],[\"BE\",0.0037],[\"SG\",0.0036],[\"CL\",0.0036],[\"VE\",0.0035],[\"DK\",0.0033],[\"PE\",0.0032],[\"MA\",0.0031],[\"IE\",0.0031],[\"IL\",0.0029],[\"YE\",0.0027],[\"CH\",0.0026],[\"RO\",0.0024],[\"HK\",0.0024],[\"GR\",0.0023],[\"CZ\",0.0023],[\"TW\",0.0021],[\"AE\",0.0021],[\"PK\",0.0021],[\"AT\",0.002],[\"NZ\",0.002],[\"HU\",0.002],[\"NO\",0.0019],[\"KZ\",0.0017],[\"??\",0.0016],[\"AF\",0.0016],[\"KR\",0.0016],[\"CR\",0.0015],[\"IQ\",0.0015],[\"BM\",0.0014],[\"UY\",0.0013],[\"SK\",0.0012],[\"DO\",0.0011],[\"TT\",0.001],[\"BG\",0.001],[\"BD\",0.001],[\"LK\",0.001],[\"BY\",9.0E-4],[\"TN\",9.0E-4],[\"NG\",9.0E-4],[\"FI\",8.0E-4],[\"PR\",8.0E-4],[\"SY\",8.0E-4],[\"RS\",8.0E-4],[\"JO\",8.0E-4],[\"GT\",7.0E-4],[\"BA\",7.0E-4],[\"BO\",7.0E-4],[\"LT\",7.0E-4],[\"KE\",7.0E-4],[\"LB\",7.0E-4],[\"UZ\",6.0E-4],[\"QA\",6.0E-4],[\"SD\",6.0E-4],[\"LY\",6.0E-4],[\"NP\",6.0E-4],[\"OM\",5.0E-4],[\"PA\",5.0E-4],[\"HN\",5.0E-4],[\"HR\",5.0E-4],[\"ET\",4.0E-4],[\"GH\",4.0E-4],[\"AZ\",4.0E-4],[\"PS\",4.0E-4],[\"AL\",4.0E-4],[\"PY\",4.0E-4],[\"SI\",4.0E-4],[\"BZ\",3.0E-4],[\"SV\",3.0E-4],[\"CI\",3.0E-4],[\"JM\",3.0E-4],[\"KW\",3.0E-4],[\"EE\",2.0E-4],[\"GE\",2.0E-4],[\"AO\",2.0E-4],[\"BW\",2.0E-4],[\"BH\",2.0E-4],[\"CY\",2.0E-4],[\"SN\",2.0E-4],[\"LV\",2.0E-4],[\"LU\",2.0E-4],[\"MK\",2.0E-4],[\"MD\",2.0E-4],[\"MU\",2.0E-4],[\"MM\",2.0E-4],[\"MT\",2.0E-4],[\"NA\",2.0E-4],[\"IS\",2.0E-4],[\"KH\",2.0E-4],[\"DJ\",1.0E-4],[\"UG\",1.0E-4],[\"TZ\",1.0E-4],[\"GY\",1.0E-4],[\"GU\",1.0E-4],[\"GP\",1.0E-4],[\"RE\",1.0E-4],[\"AM\",1.0E-4],[\"TG\",1.0E-4],[\"BS\",1.0E-4],[\"BB\",1.0E-4],[\"BN\",1.0E-4],[\"BJ\",1.0E-4],[\"CW\",1.0E-4],[\"CD\",1.0E-4],[\"CM\",1.0E-4],[\"ME\",1.0E-4],[\"MV\",1.0E-4],[\"MZ\",1.0E-4],[\"MO\",1.0E-4],[\"MQ\",1.0E-4],[\"NI\",1.0E-4],[\"NE\",1.0E-4],[\"HT\",1.0E-4],[\"ZM\",1.0E-4],[\"ZW\",1.0E-4],[\"JE\",1.0E-4],[\"KG\",1.0E-4],[\"KY\",1.0E-4],[\"LA\",1.0E-4]],\"geodiversity_normalized\":[[\"BM\",0.20375896159233017],[\"YE\",0.09244116857647527],[\"LY\",0.03906714839945628],[\"JP\",0.030247161175715482],[\"UY\",0.017327997941008564],[\"GP\",0.01611794734153928],[\"OM\",0.01584445948550431],[\"UZ\",0.012655753260989624],[\"ZA\",0.012459173513181756],[\"NA\",0.012353255907166424],[\"DJ\",0.012059048193487418],[\"ET\",0.011267448269447748],[\"NE\",0.011130948345478668],[\"TG\",0.011115586042923016],[\"MQ\",0.010917816571685718],[\"CD\",0.010133128017268738],[\"IR\",0.009554115786249174],[\"GY\",0.009020860272706092],[\"ZW\",0.008999440533249985],[\"JO\",0.008587359427940694],[\"CI\",0.008458906984088651],[\"EC\",0.008424890295545056],[\"ZM\",0.008062503221898677],[\"QA\",0.007927753403880314],[\"MA\",0.007834061862256707],[\"SD\",0.007603882043760343],[\"SA\",0.007515213996104046],[\"IL\",0.007413411654412088],[\"NP\",0.0073149722224984315],[\"LB\",0.006992890545058264],[\"PH\",0.006975493060458157],[\"TT\",0.006877277598164459],[\"MM\",0.00672071497838774],[\"NZ\",0.006606545844889045],[\"AU\",0.006420955278274985],[\"SN\",0.005953888649969115],[\"GU\",0.005444608289488192],[\"PY\",0.005383647601754953],[\"BJ\",0.005373769349274668],[\"AM\",0.005345902883036986],[\"ME\",0.0051186887386536865],[\"IN\",0.005105527493742024],[\"LK\",0.005030075492148507],[\"BZ\",0.005025008344752182],[\"MU\",0.004938319913989788],[\"SG\",0.004904747993133913],[\"BH\",0.0048228971516750836],[\"KW\",0.004798889830765654],[\"EG\",0.004619340709342588],[\"BR\",0.004599468222743493],[\"AT\",0.004540410833015574],[\"GH\",0.004520279187084444],[\"HU\",0.0045116381878804275],[\"GE\",0.004497835567036878],[\"KE\",0.004491586986786001],[\"AE\",0.004484969188213879],[\"MT\",0.004350760132876633],[\"CO\",0.0043249507554260005],[\"PT\",0.0043077022802489266],[\"MD\",0.00428657404682345],[\"MZ\",0.004127445917671008],[\"TN\",0.0038572622599467817],[\"BD\",0.0038168055504889087],[\"PE\",0.003802764959897941],[\"GT\",0.0037809849520660166],[\"BO\",0.0037776439081732686],[\"RE\",0.0037705696686448544],[\"IS\",0.0037224273209199416],[\"CZ\",0.0037113614866476213],[\"SY\",0.003700792682319089],[\"MO\",0.0036077884818748684],[\"ES\",0.0035846536395296663],[\"MX\",0.0035827810660169703],[\"BW\",0.0035818656343892972],[\"CL\",0.003554849247808106],[\"DE\",0.003531979589799978],[\"GR\",0.003524631758147203],[\"IQ\",0.0034449203973161615],[\"HK\",0.0034358080966143713],[\"KG\",0.0032849747373204486],[\"JE\",0.003256006998903569],[\"HR\",0.0032409882444745662],[\"VE\",0.0032242854277104603],[\"SV\",0.0031234464489522467],[\"KR\",0.003049835621805406],[\"AF\",0.003036249637633131],[\"RO\",0.002997571804394868],[\"CH\",0.002979705709246971],[\"KZ\",0.0029703044415169007],[\"BE\",0.0029144025985733658],[\"MV\",0.0028368296972065285],[\"CR\",0.002776258271107416],[\"BB\",0.0027733942190858846],[\"AZ\",0.0027669033344557264],[\"LT\",0.0027166143334635736],[\"FR\",0.002678444359267468],[\"KY\",0.002611575887068207],[\"HN\",0.002598002229714169],[\"FI\",0.002592164727092915],[\"KH\",0.0025637233207784207],[\"SE\",0.002559739783173962],[\"HT\",0.0025571097550423963],[\"US\",0.0024955430120255106],[\"UG\",0.0024637310529903363],[\"DO\",0.002447096492825564],[\"PA\",0.0024279688323486756],[\"NL\",0.0023297394861225263],[\"EE\",0.002320455022564876],[\"IE\",0.0023053956285744802],[\"SI\",0.002304148999054233],[\"RS\",0.0022736983175376756],[\"PS\",0.002254662648206714],[\"TW\",0.002188166300297028],[\"TZ\",0.0021626386902226457],[\"AO\",0.0021310410867562417],[\"SK\",0.0019483833374038515],[\"CA\",0.0019178395715433397],[\"BY\",0.0019097823579033273],[\"MY\",0.0018519651455630832],[\"AL\",0.0018296669943540411],[\"AR\",0.001817066969918926],[\"GB\",0.001795893396906611],[\"CY\",0.0017925147482679188],[\"LA\",0.0017850531790498205],[\"TH\",0.0017688191331781708],[\"LV\",0.0017597982819709738],[\"PL\",0.0017570479059798101],[\"JM\",0.0017179364931356996],[\"NO\",0.0016701570504380208],[\"LU\",0.0015553395089509797],[\"IT\",0.0014440301311380746],[\"NG\",0.0013904044024260944],[\"UA\",0.0013449056884677643],[\"BA\",0.0012723618350648786],[\"MK\",0.0012578380153405292],[\"??\",0.00124098909424614],[\"BS\",0.0011379132764855538],[\"PR\",0.0011252738806954998],[\"VN\",0.0011050924675411258],[\"PK\",0.0010718205066905487],[\"RU\",0.0010681750932449397],[\"ID\",9.676335777603613E-4],[\"BG\",9.381747224025812E-4],[\"CN\",8.529633575726018E-4],[\"DK\",8.518203079498652E-4],[\"CW\",7.487854976037012E-4],[\"DZ\",6.800142031102517E-4],[\"TR\",5.295034276648443E-4],[\"CM\",3.475859949117745E-4],[\"BN\",3.384718139199583E-4],[\"NI\",2.8908538206708653E-4]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"

    #domain_list = "{\"recordInfo\":{\"totalMaliciousDomain\":2},\"features\":{\"rr_count\":95}}"
    domain_list = "{\"recordInfo\":{\"totalMaliciousDomain\":5},\"features\":{\"rr_count\":55},\"records\":[{\"rr\":\"abc.com\"},{\"rr\":\"abc1.com\"}]}"
    expect(Virustotal::Scan).to receive(:scan_hashes).and_return(virus_total_nonconviction_hash).at_least(:once)
    expect(RepApi::Whitelist).to receive(:get_whitelist_info).and_raise(RepApi::RepApiNotFoundError, "HTTP response 404").at_least(:once)
    expect(Umbrella::SecurityInfo).to receive(:query_malicious_domains).and_return(domain_list).at_least(:once)
    #expect(Umbrella::Scan).to receive(:scan_result).with(address: "1.2.3.4").and_return(umbrella_scan_good).at_least(:once)
    expect(Umbrella::DomainInfo).to receive(:ip_whois).and_return("[{\"asn\":8452}]").at_least(:once)
    expect(Umbrella::SecurityInfo).to receive(:query_info).and_return(@umbrella_popular_bad).at_least(:once)

    expect(AutoResolve).to receive(:commit_to_reptool).and_return({:success => true}).at_least(:once)
    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: no_rules_ip_auto_resolve_json_allow

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    expect(dispute.dispute_entries.where(uri: '1.2.3.4')).to exist


    dispute_entry_1 = DisputeEntry.where(:uri => '1.2.3.4').first

    expect(dispute_entry_1.status).to eql("RESOLVED_CLOSED")
    expect(dispute_entry_1.resolution).to eql("AP - FN")
    expect(dispute_entry_1.resolution_comment).to eql("Talos has lowered our reputation score for the URL/Domain/Host to block access.")

    expect(dispute_entry_1.auto_resolve_category).to eql("ASN block list/low domain count")
  end

  it 'should auto resolve if hosted domains < 100, highest popularity < 40, malciious domains >= 20%' do


    umbrella_scan_good = UmbrellaScanResponse.new
    umbrella_scan_good.code = 200
    umbrella_scan_good.body = "{\"google.com\":{\"status\":1,\"security_categories\":[],\"content_categories\":[\"23\"]}}"

    @umbrella_popular_bad = UmbrellaSecurityInfoResponse.new
    @umbrella_popular_bad.code = 200
    @umbrella_popular_bad.body = "{\"dga_score\":0.0,\"perplexity\":0.1698321879522074,\"entropy\":3.4594316186372978,\"securerank2\":0.0,\"pagerank\":0.0,\"asn_score\":-0.014739406284196042,\"prefix_score\":-0.023982712069696013,\"rip_score\":-0.011198019721606252,\"popularity\":0.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.5],[\"BR\",0.5]],\"geodiversity_normalized\":[[\"BR\",0.863526213328589],[\"US\",0.13647378667141086]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"


    umbrella_popular_good = UmbrellaSecurityInfoResponse.new
    umbrella_popular_good.code = 200
    umbrella_popular_good.body = "{\"dga_score\":0.0,\"perplexity\":0.18786756104373362,\"entropy\":1.9182958340544896,\"securerank2\":100.0,\"pagerank\":63.36242,\"asn_score\":-0.07587332170749107,\"prefix_score\":-0.02867604643567799,\"rip_score\":-0.12451293522019732,\"popularity\":100.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.3591],[\"BR\",0.1046],[\"IN\",0.0603],[\"CA\",0.0358],[\"GB\",0.0344],[\"EG\",0.0288],[\"TR\",0.0216],[\"VN\",0.0202],[\"IT\",0.02],[\"MX\",0.0169],[\"DE\",0.0162],[\"FR\",0.0152],[\"AU\",0.0138],[\"JP\",0.0129],[\"PH\",0.0126],[\"RU\",0.0113],[\"ES\",0.0106],[\"IR\",0.0098],[\"NL\",0.0085],[\"PL\",0.0085],[\"ID\",0.0072],[\"CN\",0.0071],[\"AR\",0.007],[\"MY\",0.007],[\"UA\",0.0068],[\"DZ\",0.0064],[\"CO\",0.0056],[\"EC\",0.0053],[\"ZA\",0.005],[\"PT\",0.0047],[\"SE\",0.0045],[\"SA\",0.0039],[\"TH\",0.0038],[\"BE\",0.0037],[\"SG\",0.0036],[\"CL\",0.0036],[\"VE\",0.0035],[\"DK\",0.0033],[\"PE\",0.0032],[\"MA\",0.0031],[\"IE\",0.0031],[\"IL\",0.0029],[\"YE\",0.0027],[\"CH\",0.0026],[\"RO\",0.0024],[\"HK\",0.0024],[\"GR\",0.0023],[\"CZ\",0.0023],[\"TW\",0.0021],[\"AE\",0.0021],[\"PK\",0.0021],[\"AT\",0.002],[\"NZ\",0.002],[\"HU\",0.002],[\"NO\",0.0019],[\"KZ\",0.0017],[\"??\",0.0016],[\"AF\",0.0016],[\"KR\",0.0016],[\"CR\",0.0015],[\"IQ\",0.0015],[\"BM\",0.0014],[\"UY\",0.0013],[\"SK\",0.0012],[\"DO\",0.0011],[\"TT\",0.001],[\"BG\",0.001],[\"BD\",0.001],[\"LK\",0.001],[\"BY\",9.0E-4],[\"TN\",9.0E-4],[\"NG\",9.0E-4],[\"FI\",8.0E-4],[\"PR\",8.0E-4],[\"SY\",8.0E-4],[\"RS\",8.0E-4],[\"JO\",8.0E-4],[\"GT\",7.0E-4],[\"BA\",7.0E-4],[\"BO\",7.0E-4],[\"LT\",7.0E-4],[\"KE\",7.0E-4],[\"LB\",7.0E-4],[\"UZ\",6.0E-4],[\"QA\",6.0E-4],[\"SD\",6.0E-4],[\"LY\",6.0E-4],[\"NP\",6.0E-4],[\"OM\",5.0E-4],[\"PA\",5.0E-4],[\"HN\",5.0E-4],[\"HR\",5.0E-4],[\"ET\",4.0E-4],[\"GH\",4.0E-4],[\"AZ\",4.0E-4],[\"PS\",4.0E-4],[\"AL\",4.0E-4],[\"PY\",4.0E-4],[\"SI\",4.0E-4],[\"BZ\",3.0E-4],[\"SV\",3.0E-4],[\"CI\",3.0E-4],[\"JM\",3.0E-4],[\"KW\",3.0E-4],[\"EE\",2.0E-4],[\"GE\",2.0E-4],[\"AO\",2.0E-4],[\"BW\",2.0E-4],[\"BH\",2.0E-4],[\"CY\",2.0E-4],[\"SN\",2.0E-4],[\"LV\",2.0E-4],[\"LU\",2.0E-4],[\"MK\",2.0E-4],[\"MD\",2.0E-4],[\"MU\",2.0E-4],[\"MM\",2.0E-4],[\"MT\",2.0E-4],[\"NA\",2.0E-4],[\"IS\",2.0E-4],[\"KH\",2.0E-4],[\"DJ\",1.0E-4],[\"UG\",1.0E-4],[\"TZ\",1.0E-4],[\"GY\",1.0E-4],[\"GU\",1.0E-4],[\"GP\",1.0E-4],[\"RE\",1.0E-4],[\"AM\",1.0E-4],[\"TG\",1.0E-4],[\"BS\",1.0E-4],[\"BB\",1.0E-4],[\"BN\",1.0E-4],[\"BJ\",1.0E-4],[\"CW\",1.0E-4],[\"CD\",1.0E-4],[\"CM\",1.0E-4],[\"ME\",1.0E-4],[\"MV\",1.0E-4],[\"MZ\",1.0E-4],[\"MO\",1.0E-4],[\"MQ\",1.0E-4],[\"NI\",1.0E-4],[\"NE\",1.0E-4],[\"HT\",1.0E-4],[\"ZM\",1.0E-4],[\"ZW\",1.0E-4],[\"JE\",1.0E-4],[\"KG\",1.0E-4],[\"KY\",1.0E-4],[\"LA\",1.0E-4]],\"geodiversity_normalized\":[[\"BM\",0.20375896159233017],[\"YE\",0.09244116857647527],[\"LY\",0.03906714839945628],[\"JP\",0.030247161175715482],[\"UY\",0.017327997941008564],[\"GP\",0.01611794734153928],[\"OM\",0.01584445948550431],[\"UZ\",0.012655753260989624],[\"ZA\",0.012459173513181756],[\"NA\",0.012353255907166424],[\"DJ\",0.012059048193487418],[\"ET\",0.011267448269447748],[\"NE\",0.011130948345478668],[\"TG\",0.011115586042923016],[\"MQ\",0.010917816571685718],[\"CD\",0.010133128017268738],[\"IR\",0.009554115786249174],[\"GY\",0.009020860272706092],[\"ZW\",0.008999440533249985],[\"JO\",0.008587359427940694],[\"CI\",0.008458906984088651],[\"EC\",0.008424890295545056],[\"ZM\",0.008062503221898677],[\"QA\",0.007927753403880314],[\"MA\",0.007834061862256707],[\"SD\",0.007603882043760343],[\"SA\",0.007515213996104046],[\"IL\",0.007413411654412088],[\"NP\",0.0073149722224984315],[\"LB\",0.006992890545058264],[\"PH\",0.006975493060458157],[\"TT\",0.006877277598164459],[\"MM\",0.00672071497838774],[\"NZ\",0.006606545844889045],[\"AU\",0.006420955278274985],[\"SN\",0.005953888649969115],[\"GU\",0.005444608289488192],[\"PY\",0.005383647601754953],[\"BJ\",0.005373769349274668],[\"AM\",0.005345902883036986],[\"ME\",0.0051186887386536865],[\"IN\",0.005105527493742024],[\"LK\",0.005030075492148507],[\"BZ\",0.005025008344752182],[\"MU\",0.004938319913989788],[\"SG\",0.004904747993133913],[\"BH\",0.0048228971516750836],[\"KW\",0.004798889830765654],[\"EG\",0.004619340709342588],[\"BR\",0.004599468222743493],[\"AT\",0.004540410833015574],[\"GH\",0.004520279187084444],[\"HU\",0.0045116381878804275],[\"GE\",0.004497835567036878],[\"KE\",0.004491586986786001],[\"AE\",0.004484969188213879],[\"MT\",0.004350760132876633],[\"CO\",0.0043249507554260005],[\"PT\",0.0043077022802489266],[\"MD\",0.00428657404682345],[\"MZ\",0.004127445917671008],[\"TN\",0.0038572622599467817],[\"BD\",0.0038168055504889087],[\"PE\",0.003802764959897941],[\"GT\",0.0037809849520660166],[\"BO\",0.0037776439081732686],[\"RE\",0.0037705696686448544],[\"IS\",0.0037224273209199416],[\"CZ\",0.0037113614866476213],[\"SY\",0.003700792682319089],[\"MO\",0.0036077884818748684],[\"ES\",0.0035846536395296663],[\"MX\",0.0035827810660169703],[\"BW\",0.0035818656343892972],[\"CL\",0.003554849247808106],[\"DE\",0.003531979589799978],[\"GR\",0.003524631758147203],[\"IQ\",0.0034449203973161615],[\"HK\",0.0034358080966143713],[\"KG\",0.0032849747373204486],[\"JE\",0.003256006998903569],[\"HR\",0.0032409882444745662],[\"VE\",0.0032242854277104603],[\"SV\",0.0031234464489522467],[\"KR\",0.003049835621805406],[\"AF\",0.003036249637633131],[\"RO\",0.002997571804394868],[\"CH\",0.002979705709246971],[\"KZ\",0.0029703044415169007],[\"BE\",0.0029144025985733658],[\"MV\",0.0028368296972065285],[\"CR\",0.002776258271107416],[\"BB\",0.0027733942190858846],[\"AZ\",0.0027669033344557264],[\"LT\",0.0027166143334635736],[\"FR\",0.002678444359267468],[\"KY\",0.002611575887068207],[\"HN\",0.002598002229714169],[\"FI\",0.002592164727092915],[\"KH\",0.0025637233207784207],[\"SE\",0.002559739783173962],[\"HT\",0.0025571097550423963],[\"US\",0.0024955430120255106],[\"UG\",0.0024637310529903363],[\"DO\",0.002447096492825564],[\"PA\",0.0024279688323486756],[\"NL\",0.0023297394861225263],[\"EE\",0.002320455022564876],[\"IE\",0.0023053956285744802],[\"SI\",0.002304148999054233],[\"RS\",0.0022736983175376756],[\"PS\",0.002254662648206714],[\"TW\",0.002188166300297028],[\"TZ\",0.0021626386902226457],[\"AO\",0.0021310410867562417],[\"SK\",0.0019483833374038515],[\"CA\",0.0019178395715433397],[\"BY\",0.0019097823579033273],[\"MY\",0.0018519651455630832],[\"AL\",0.0018296669943540411],[\"AR\",0.001817066969918926],[\"GB\",0.001795893396906611],[\"CY\",0.0017925147482679188],[\"LA\",0.0017850531790498205],[\"TH\",0.0017688191331781708],[\"LV\",0.0017597982819709738],[\"PL\",0.0017570479059798101],[\"JM\",0.0017179364931356996],[\"NO\",0.0016701570504380208],[\"LU\",0.0015553395089509797],[\"IT\",0.0014440301311380746],[\"NG\",0.0013904044024260944],[\"UA\",0.0013449056884677643],[\"BA\",0.0012723618350648786],[\"MK\",0.0012578380153405292],[\"??\",0.00124098909424614],[\"BS\",0.0011379132764855538],[\"PR\",0.0011252738806954998],[\"VN\",0.0011050924675411258],[\"PK\",0.0010718205066905487],[\"RU\",0.0010681750932449397],[\"ID\",9.676335777603613E-4],[\"BG\",9.381747224025812E-4],[\"CN\",8.529633575726018E-4],[\"DK\",8.518203079498652E-4],[\"CW\",7.487854976037012E-4],[\"DZ\",6.800142031102517E-4],[\"TR\",5.295034276648443E-4],[\"CM\",3.475859949117745E-4],[\"BN\",3.384718139199583E-4],[\"NI\",2.8908538206708653E-4]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"

    #domain_list = "{\"recordInfo\":{\"totalMaliciousDomain\":2},\"features\":{\"rr_count\":95}}"
    domain_list = "{\"recordInfo\":{\"totalMaliciousDomain\":51},\"features\":{\"rr_count\":55},\"records\":[{\"rr\":\"abc.com\"},{\"rr\":\"abc1.com\"}]}"
    expect(Virustotal::Scan).to receive(:scan_hashes).and_return(virus_total_nonconviction_hash).at_least(:once)
    expect(RepApi::Whitelist).to receive(:get_whitelist_info).and_raise(RepApi::RepApiNotFoundError, "HTTP response 404").at_least(:once)
    expect(Umbrella::SecurityInfo).to receive(:query_malicious_domains).and_return(domain_list).at_least(:once)
    #expect(Umbrella::Scan).to receive(:scan_result).with(address: "1.2.3.4").and_return(umbrella_scan_good).at_least(:once)
    expect(Umbrella::DomainInfo).to receive(:ip_whois).and_return("[{\"asn\":8451}]").at_least(:once)
    expect(Umbrella::SecurityInfo).to receive(:query_info).and_return(@umbrella_popular_bad).at_least(:once)

    expect(AutoResolve).to receive(:commit_to_reptool).and_return({:success => true}).at_least(:once)
    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: no_rules_ip_auto_resolve_json_allow

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)
    expect(dispute.dispute_entries.where(uri: '1.2.3.4')).to exist


    dispute_entry_1 = DisputeEntry.where(:uri => '1.2.3.4').first

    expect(dispute_entry_1.status).to eql("RESOLVED_CLOSED")
    expect(dispute_entry_1.resolution).to eql("AP - FN")
    expect(dispute_entry_1.resolution_comment).to eql("Talos has lowered our reputation score for the URL/Domain/Host to block access.")

    expect(dispute_entry_1.auto_resolve_category).to eql("20% malicious ratio/low domain count")

  end

end
