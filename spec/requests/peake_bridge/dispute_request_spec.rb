require "rails_helper"

RSpec.describe "Peake-Bridge dispute messages channels", type: :request do
  let(:vrt_incoming) { FactoryBot.create(:vrt_incoming_user) }
  let(:guest_company) { FactoryBot.create(:guest_company) }
  let(:company_name) { 'WRMC' }
  let(:customer_name) { '3-Support Support' }
  let(:customer_email) { 'webmaster@cmim.org' }
  let(:existing_company) { FactoryBot.create(:company, name: company_name) }
  let(:existing_customer) do
    FactoryBot.create(:customer, name: customer_name, email: customer_email, company: existing_company)
  end


  let(:dispute_message_alt_json) do
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
                    investigate_ips: {
                    },
                    investigate_urls: {
                        "45.155.205.151" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Untrusted",
                            "claim" => "false negative",
                            "category"=>"Not in our list"
                        }
                    },
                    problem: 'What do I need to do to improve the reputation',
                    submission_type: 'w',
                    name: customer_name,
                    user_company: company_name,
                    email: 'webmaster@cmim.org',
                    email_subject: 'Now AC is ready, 355 Toyota and The Pretenders reputation dispute.',
                    email_body: "____________________________________________________________\nUser-entered Information:\n____________________________________________________________\nTime: October 11, 2018 16:15\nName: Marlin Pierce\nE-mail: marlpier@cisco.com\nDomain: cisco.com\nInquiry Type: web\nKey Rules: \nProblem Summary: Now AC is ready, 355 Toyota and The Pretenders reputation dispute.\nIP(s) to be investigated:\n64.70.56.99\n184.168.47.225\n\nURI(s) to be investigated:\n355toyota.com\nthepretenders.com\n\nDetailed Descriptions:\n\n\n____________________________________________________________\nCisco Confidential Analysis:\n____________________________________________________________\n\nUser's IP:      ::1\n\n64.70.56.99\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       www.dealer.com\n\n184.168.47.225\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       redirect-v225.secureserver.net\n\n355toyota.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n\nthepretenders.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n",
                    user_ip: '64.70.56.99',
                    domain: '355toyota.com',
                    product_platform: 1001,
                    product_version: "test_platform_version"
                }
            }
        }
    }
  end


  let(:dispute_message_alt_json_positive) do
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
                    investigate_ips: {
                        "64.70.56.99" => {
                            "wbrs" => {
                                "WBRS_SCORE"=>"-3.55",
                                "WBRS_Rule_Hits"=>"dotq",
                                "Hostname_ips"=>"",
                                "rep_sugg"=>"Good",
                                "category"=>"Not in our list"
                            },
                            "sbrs" => {
                                "SBRS_SCORE"=>"No score",
                                "SBRS_Rule_Hits"=>"",
                                "Hostname"=>"www.dealer.com",
                                "rep_sugg"=>"Good",
                                "claim" => "false positive",
                                "category"=>"Not in our list"
                            }
                        },
                    },
                    investigate_urls: {
                    },
                    problem: 'What do I need to do to improve the reputation',
                    submission_type: 'e',
                    name: "non-customer-name",
                    user_company: "Guest",
                    email: 'webmaster@cmim.org',
                    email_subject: 'Now AC is ready, 355 Toyota and The Pretenders reputation dispute.',
                    email_body: "____________________________________________________________\nUser-entered Information:\n____________________________________________________________\nTime: October 11, 2018 16:15\nName: Marlin Pierce\nE-mail: marlpier@cisco.com\nDomain: cisco.com\nInquiry Type: web\nKey Rules: \nProblem Summary: Now AC is ready, 355 Toyota and The Pretenders reputation dispute.\nIP(s) to be investigated:\n64.70.56.99\n184.168.47.225\n\nURI(s) to be investigated:\n355toyota.com\nthepretenders.com\n\nDetailed Descriptions:\n\n\n____________________________________________________________\nCisco Confidential Analysis:\n____________________________________________________________\n\nUser's IP:      ::1\n\n64.70.56.99\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       www.dealer.com\n\n184.168.47.225\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       redirect-v225.secureserver.net\n\n355toyota.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n\nthepretenders.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n",
                    user_ip: '64.70.56.99',
                    domain: '355toyota.com',
                    product_platform: 1001,
                    product_version: "test_platform_version"
                }
            }
        }
    }
  end

  let(:dispute_message_alt_json_negative) do
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
                    investigate_ips: {
                        "64.70.56.99" => {
                            "wbrs" => {
                                "WBRS_SCORE"=>"-3.55",
                                "WBRS_Rule_Hits"=>"dotq",
                                "Hostname_ips"=>"",
                                "rep_sugg"=>"Good",
                                "category"=>"Not in our list"
                            },
                            "sbrs" => {
                                "SBRS_SCORE"=>"No score",
                                "SBRS_Rule_Hits"=>"",
                                "Hostname"=>"www.dealer.com",
                                "rep_sugg"=>"Good",
                                "claim" => "false negative",
                                "category"=>"Not in our list"
                            }
                        },
                    },
                    investigate_urls: {
                    },
                    problem: 'What do I need to do to improve the reputation',
                    submission_type: 'e',
                    name: "non-customer-name",
                    user_company: "Guest",
                    email: 'webmaster@cmim.org',
                    email_subject: 'Now AC is ready, 355 Toyota and The Pretenders reputation dispute.',
                    email_body: "____________________________________________________________\nUser-entered Information:\n____________________________________________________________\nTime: October 11, 2018 16:15\nName: Marlin Pierce\nE-mail: marlpier@cisco.com\nDomain: cisco.com\nInquiry Type: web\nKey Rules: \nProblem Summary: Now AC is ready, 355 Toyota and The Pretenders reputation dispute.\nIP(s) to be investigated:\n64.70.56.99\n184.168.47.225\n\nURI(s) to be investigated:\n355toyota.com\nthepretenders.com\n\nDetailed Descriptions:\n\n\n____________________________________________________________\nCisco Confidential Analysis:\n____________________________________________________________\n\nUser's IP:      ::1\n\n64.70.56.99\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       www.dealer.com\n\n184.168.47.225\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       redirect-v225.secureserver.net\n\n355toyota.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n\nthepretenders.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n",
                    user_ip: '64.70.56.99',
                    domain: '355toyota.com',
                    product_platform: 1001,
                    product_version: "test_platform_version"
                }
            }
        }
    }
  end

  let(:umbrella_dispute_message_json) do
    {
        envelope: {
            channel: "ticket-event",
            addressee: "analyst-console-escalations",
            sender: "talos-intelligence"
        },
        message: {
            dispute: {
                source_type: 'Dispute',
                source_key: 2001,
                payload: {
                    investigate_ips: {
                    },
                    investigate_urls: {
                        "355toyota.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Untrusted",
                            "claim" => "false negative",
                            "category"=>"Not in our list"
                        }
                    },
                    problem: 'What do I need to do to improve the reputation',
                    submission_type: 'w',
                    name: customer_name,
                    user_company: company_name,
                    email: 'webmaster@cmim.org',
                    email_subject: 'Now AC is ready, 355 Toyota and The Pretenders reputation dispute.',
                    email_body: "____________________________________________________________\nUser-entered Information:\n____________________________________________________________\nTime: October 11, 2018 16:15\nName: Marlin Pierce\nE-mail: marlpier@cisco.com\nDomain: cisco.com\nInquiry Type: web\nKey Rules: \nProblem Summary: Now AC is ready, 355 Toyota and The Pretenders reputation dispute.\nIP(s) to be investigated:\n64.70.56.99\n184.168.47.225\n\nURI(s) to be investigated:\n355toyota.com\nthepretenders.com\n\nDetailed Descriptions:\n\n\n____________________________________________________________\nCisco Confidential Analysis:\n____________________________________________________________\n\nUser's IP:      ::1\n\n64.70.56.99\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       www.dealer.com\n\n184.168.47.225\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       redirect-v225.secureserver.net\n\n355toyota.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n\nthepretenders.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n",
                    user_ip: '64.70.56.99',
                    domain: '355toyota.com',
                    product_platform: 1000,
                    product_version: "test_platform_version"
                }
            }
        }
    }
  end

  let(:non_umbrella_dispute_message_json) do
    {
        envelope: {
            channel: "ticket-event",
            addressee: "analyst-console-escalations",
            sender: "talos-intelligence"
        },
        message: {
            dispute: {
                source_type: 'Dispute',
                source_key: 3001,
                payload: {
                    investigate_ips: {
                    },
                    investigate_urls: {
                        "355toyota.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Good",
                            "claim" => "false positive",
                            "category"=>"Not in our list"
                        }
                    },
                    problem: 'What do I need to do to improve the reputation',
                    submission_type: 'w',
                    name: customer_name,
                    user_company: company_name,
                    email: 'webmaster@cmim.org',
                    email_subject: 'Now AC is ready, 355 Toyota and The Pretenders reputation dispute.',
                    email_body: "____________________________________________________________\nUser-entered Information:\n____________________________________________________________\nTime: October 11, 2018 16:15\nName: Marlin Pierce\nE-mail: marlpier@cisco.com\nDomain: cisco.com\nInquiry Type: web\nKey Rules: \nProblem Summary: Now AC is ready, 355 Toyota and The Pretenders reputation dispute.\nIP(s) to be investigated:\n64.70.56.99\n184.168.47.225\n\nURI(s) to be investigated:\n355toyota.com\nthepretenders.com\n\nDetailed Descriptions:\n\n\n____________________________________________________________\nCisco Confidential Analysis:\n____________________________________________________________\n\nUser's IP:      ::1\n\n64.70.56.99\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       www.dealer.com\n\n184.168.47.225\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       redirect-v225.secureserver.net\n\n355toyota.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n\nthepretenders.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n",
                    user_ip: '64.70.56.99',
                    domain: '355toyota.com',
                    product_platform: 1001,
                    product_version: "test_platform_version"
                }
            }
        }
    }
  end



  let(:weird_dispute_message_json) do
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
                    investigate_ips: {
                    },
                    investigate_urls: {
                        "355toyota.com:3000/some/path" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Good",
                            "claim" => "false positive",
                            "category"=>"Not in our list"
                        },
                        "testing@gmail.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Good",
                            "claim" => "false positive",
                            "category"=>"Entertainment"
                        },
                        "https://ELECTRIC.cars.gov:23234/some/path.php?this=that&that=this" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Good",
                            "claim" => "false positive",
                            "category"=>"Entertainment"
                        }
                    },
                    problem: 'What do I need to do to improve the reputation',
                    submission_type: 'w',
                    name: customer_name,
                    user_company: company_name,
                    email: 'webmaster@cmim.org',
                    email_subject: 'Now AC is ready, 355 Toyota and The Pretenders reputation dispute.',
                    email_body: "____________________________________________________________\nUser-entered Information:\n____________________________________________________________\nTime: October 11, 2018 16:15\nName: Marlin Pierce\nE-mail: marlpier@cisco.com\nDomain: cisco.com\nInquiry Type: web\nKey Rules: \nProblem Summary: Now AC is ready, 355 Toyota and The Pretenders reputation dispute.\nIP(s) to be investigated:\n64.70.56.99\n184.168.47.225\n\nURI(s) to be investigated:\n355toyota.com\nthepretenders.com\n\nDetailed Descriptions:\n\n\n____________________________________________________________\nCisco Confidential Analysis:\n____________________________________________________________\n\nUser's IP:      ::1\n\n64.70.56.99\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       www.dealer.com\n\n184.168.47.225\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       redirect-v225.secureserver.net\n\n355toyota.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n\nthepretenders.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n",
                    user_ip: '64.70.56.99',
                    domain: '355toyota.com',
                    product_platform: 1001,
                    product_version: "test_platform_version"
                }
            }
        }
    }
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
                    investigate_ips: {
                        "64.70.56.99" => {
                            "wbrs" => {
                                "WBRS_SCORE"=>"-3.55",
                                "WBRS_Rule_Hits"=>"dotq",
                                "Hostname_ips"=>"",
                                "rep_sugg"=>"Good",
                                "category"=>"Not in our list"
                            },
                            "sbrs" => {
                                "SBRS_SCORE"=>"No score",
                                "SBRS_Rule_Hits"=>"",
                                "Hostname"=>"www.dealer.com",
                                "rep_sugg"=>"Good",
                                "claim" => "false positive",
                                "category"=>"Not in our list"
                            }
                        },
                        "184.168.47.225"=>{
                            "wbrs" => {
                                "WBRS_SCORE"=>"-3.55",
                                "WBRS_Rule_Hits"=>"dotq",
                                "Hostname_ips"=>"",
                                "rep_sugg"=>"Good",
                                "category"=>"Search Engines and Portals"
                            },
                            "sbrs" => {
                                "SBRS_SCORE"=>"No score",
                                "SBRS_Rule_Hits"=>"",
                                "Hostname"=>"redirect-v225.secureserver.net",
                                "rep_sugg"=>"Good",
                                "claim" => "false positive",
                                "category"=>"Search Engines and Portals"
                            }
                        }
                    },
                    investigate_urls: {
                        "355toyota.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Good",
                            "claim" => "false positive",
                            "category"=>"Not in our list"
                        },
                        "thepretenders.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Good",
                            "claim" => "false positive",
                            "category"=>"Entertainment"
                        }
                    },
                    problem: 'What do I need to do to improve the reputation',
                    submission_type: 'w',
                    name: customer_name,
                    user_company: company_name,
                    email: 'webmaster@cmim.org',
                    email_subject: 'Now AC is ready, 355 Toyota and The Pretenders reputation dispute.',
                    email_body: "____________________________________________________________\nUser-entered Information:\n____________________________________________________________\nTime: October 11, 2018 16:15\nName: Marlin Pierce\nE-mail: marlpier@cisco.com\nDomain: cisco.com\nInquiry Type: web\nKey Rules: \nProblem Summary: Now AC is ready, 355 Toyota and The Pretenders reputation dispute.\nIP(s) to be investigated:\n64.70.56.99\n184.168.47.225\n\nURI(s) to be investigated:\n355toyota.com\nthepretenders.com\n\nDetailed Descriptions:\n\n\n____________________________________________________________\nCisco Confidential Analysis:\n____________________________________________________________\n\nUser's IP:      ::1\n\n64.70.56.99\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       www.dealer.com\n\n184.168.47.225\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       redirect-v225.secureserver.net\n\n355toyota.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n\nthepretenders.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n",
                    user_ip: '64.70.56.99',
                    domain: '355toyota.com',
                    product_platform: 1001,
                    product_version: "test_platform_version"
                }
            }
        }
    }
  end

  let(:ti_api_message_json_non_network) do
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
                source: 'talos-intelligence-api',
                payload: {
                    investigate_ips: {
                        "64.70.56.99" => {
                            "wbrs" => {
                                "WBRS_SCORE"=>"-3.55",
                                "WBRS_Rule_Hits"=>"dotq",
                                "Hostname_ips"=>"",
                                "rep_sugg"=>"Good",
                                "category"=>"Not in our list"
                            },
                            "sbrs" => {
                                "SBRS_SCORE"=>"No score",
                                "SBRS_Rule_Hits"=>"",
                                "Hostname"=>"www.dealer.com",
                                "rep_sugg"=>"Good",
                                "claim" => "false positive",
                                "category"=>"Not in our list"
                            }
                        },
                        "184.168.47.225"=>{
                            "wbrs" => {
                                "WBRS_SCORE"=>"-3.55",
                                "WBRS_Rule_Hits"=>"dotq",
                                "Hostname_ips"=>"",
                                "rep_sugg"=>"Good",
                                "claim" => "false positive",
                                "category"=>"Search Engines and Portals"
                            },
                            "sbrs" => {
                                "SBRS_SCORE"=>"No score",
                                "SBRS_Rule_Hits"=>"",
                                "Hostname"=>"redirect-v225.secureserver.net",
                                "rep_sugg"=>"Good",
                                "claim" => "false positive",
                                "category"=>"Search Engines and Portals"
                            }
                        }
                    },
                    investigate_urls: {
                        "355toyota.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Good",
                            "claim" => "false positive",
                            "category"=>"Not in our list"
                        },
                        "thepretenders.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Good",
                            "claim" => "false positive",
                            "category"=>"Entertainment"
                        }
                    },
                    problem: 'What do I need to do to improve the reputation',
                    submission_type: 'w',
                    name: customer_name,
                    user_company: company_name,
                    email: 'webmaster@cmim.org',
                    email_subject: 'Now AC is ready, 355 Toyota and The Pretenders reputation dispute.',
                    email_body: "____________________________________________________________\nUser-entered Information:\n____________________________________________________________\nTime: October 11, 2018 16:15\nName: Marlin Pierce\nE-mail: marlpier@cisco.com\nDomain: cisco.com\nInquiry Type: web\nKey Rules: \nProblem Summary: Now AC is ready, 355 Toyota and The Pretenders reputation dispute.\nIP(s) to be investigated:\n64.70.56.99\n184.168.47.225\n\nURI(s) to be investigated:\n355toyota.com\nthepretenders.com\n\nDetailed Descriptions:\n\n\n____________________________________________________________\nCisco Confidential Analysis:\n____________________________________________________________\n\nUser's IP:      ::1\n\n64.70.56.99\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       www.dealer.com\n\n184.168.47.225\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       redirect-v225.secureserver.net\n\n355toyota.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n\nthepretenders.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n",
                    user_ip: '64.70.56.99',
                    domain: '355toyota.com',
                    product_platform: 1001,
                    product_version: "test_platform_version",
                    network: false,
                    meta_data: "{\"ticket\":{\"testing_ticket\":123},\"entry\":{\"testing_entry\":123}}"
                }
            }
        }
    }

  end

  let(:ti_api_message_json_in_network) do
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
                    investigate_ips: {
                        "64.70.56.99" => {
                            "wbrs" => {
                                "WBRS_SCORE"=>"-3.55",
                                "WBRS_Rule_Hits"=>"dotq",
                                "Hostname_ips"=>"",
                                "rep_sugg"=>"Good",
                                "category"=>"Not in our list"
                            },
                            "sbrs" => {
                                "SBRS_SCORE"=>"No score",
                                "SBRS_Rule_Hits"=>"",
                                "Hostname"=>"www.dealer.com",
                                "rep_sugg"=>"Good",
                                "claim" => "false positive",
                                "category"=>"Not in our list"
                            }
                        },
                        "184.168.47.225"=>{
                            "wbrs" => {
                                "WBRS_SCORE"=>"-3.55",
                                "WBRS_Rule_Hits"=>"dotq",
                                "Hostname_ips"=>"",
                                "rep_sugg"=>"Good",
                                "category"=>"Search Engines and Portals"
                            },
                            "sbrs" => {
                                "SBRS_SCORE"=>"No score",
                                "SBRS_Rule_Hits"=>"",
                                "Hostname"=>"redirect-v225.secureserver.net",
                                "rep_sugg"=>"Good",
                                "claim" => "false positive",
                                "category"=>"Search Engines and Portals"
                            }
                        }
                    },
                    investigate_urls: {
                        "355toyota.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Good",
                            "claim" => "false positive",
                            "category"=>"Not in our list"
                        },
                        "thepretenders.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Good",
                            "claim" => "false positive",
                            "category"=>"Entertainment"
                        }
                    },
                    problem: 'What do I need to do to improve the reputation',
                    submission_type: 'w',
                    name: customer_name,
                    user_company: company_name,
                    email: 'webmaster@cmim.org',
                    email_subject: 'Now AC is ready, 355 Toyota and The Pretenders reputation dispute.',
                    email_body: "____________________________________________________________\nUser-entered Information:\n____________________________________________________________\nTime: October 11, 2018 16:15\nName: Marlin Pierce\nE-mail: marlpier@cisco.com\nDomain: cisco.com\nInquiry Type: web\nKey Rules: \nProblem Summary: Now AC is ready, 355 Toyota and The Pretenders reputation dispute.\nIP(s) to be investigated:\n64.70.56.99\n184.168.47.225\n\nURI(s) to be investigated:\n355toyota.com\nthepretenders.com\n\nDetailed Descriptions:\n\n\n____________________________________________________________\nCisco Confidential Analysis:\n____________________________________________________________\n\nUser's IP:      ::1\n\n64.70.56.99\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       www.dealer.com\n\n184.168.47.225\nSBRS Score:     No score\nSBRS Rule Hits: \nHostname:       redirect-v225.secureserver.net\n\n355toyota.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n\nthepretenders.com\nWBRS Score:     No score\nWBRS Rule Hits: \nHostname's IPs: \n",
                    user_ip: '64.70.56.99',
                    domain: '355toyota.com',
                    product_platform: 1001,
                    product_version: "test_platform_version",
                    network: true

                }
            }
        }
    }

  end

  before(:each) do
    DelayedJob.destroy_all
    @original_platform = Platform.new
    @original_platform.id = 1001
    @original_platform.public_name = "test"
    @original_platform.internal_name = "test internal"
    @original_platform.active = true
    @original_platform.webrep = true
    @original_platform.webcat = true
    @original_platform.filerep = true
    @original_platform.emailrep = true
    @original_platform.save
  end

  after(:each) do
    Platform.destroy_all
  end

  it 'receives dispute payload messages' do
    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: dispute_message_json

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(4)
    expect(dispute.dispute_entries.where(ip_address: '64.70.56.99')).to exist
    expect(dispute.dispute_entries.where(ip_address: '184.168.47.225')).to exist
    expect(dispute.dispute_entries.where(uri: '355toyota.com')).to exist
    expect(dispute.dispute_entries.where(uri: 'thepretenders.com')).to exist
    expect(dispute.ticket_source).to eql("talos-intelligence")
    expect(dispute.platform_id).to eql(1001)
    expect(dispute.product_platform).to eql(nil)
  end

  it 'receives dispute message with ip address url and populates additional scores and rulehits' do
    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: dispute_message_alt_json

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(1)

    expect(dispute.dispute_entries.where(uri: '45.155.205.151')).to exist

    expect(dispute.ticket_source).to eql("talos-intelligence")
    expect(dispute.platform_id).to eql(1001)

    dispute_entry = dispute.dispute_entries.first

    expect(dispute_entry.web_ips).to eql("[\"45.155.205.151\"]")

    expect(dispute_entry.multi_wbrs_threat_category).to eql("[\"Malicious Sites\"]")
    expect(dispute_entry.score).to eql(-8.8)
    expect(dispute.dispute_entries.first.dispute_rule_hits.pluck(:is_multi_ip_rulehit).uniq).to eql([true])

  end

  it 'receives dispute payload message from TI API not in-network' do
    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: ti_api_message_json_non_network

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(4)
    expect(dispute.dispute_entries.where(ip_address: '64.70.56.99')).to exist
    expect(dispute.dispute_entries.where(ip_address: '184.168.47.225')).to exist
    expect(dispute.dispute_entries.where(uri: '355toyota.com')).to exist
    expect(dispute.dispute_entries.where(uri: 'thepretenders.com')).to exist

    expect(dispute.product_version).to eql("test_platform_version")
    expect(dispute.in_network).to eql(nil)
    expect(dispute.ticket_source).to eql("talos-intelligence-api")
    expect(dispute.meta_data).to eql("{\"ticket\":{\"testing_ticket\":123},\"entry\":{\"testing_entry\":123}}")
    expect(dispute.platform_id).to eql(1001)
    expect(dispute.product_platform).to eql(nil)
  end

  it 'receives dispute payload message from TI API in-network' do
    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: ti_api_message_json_in_network

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(4)
    expect(dispute.dispute_entries.where(ip_address: '64.70.56.99')).to exist
    expect(dispute.dispute_entries.where(ip_address: '184.168.47.225')).to exist
    expect(dispute.dispute_entries.where(uri: '355toyota.com')).to exist
    expect(dispute.dispute_entries.where(uri: 'thepretenders.com')).to exist

    expect(dispute.product_version).to eql("test_platform_version")
    expect(dispute.in_network).to eql(true)
    expect(dispute.dispute_comments.size).to eql(1)
    expect(dispute.dispute_comments.first.comment).to include("Dispute is [in network], IPS bugzilla bug created. Reference Bugzilla ID: #{ResearchBug.all.first.id}" )
    expect(dispute.platform_id).to eql(1001)
    expect(dispute.product_platform).to eql(nil)
    expect(ResearchBug.all.size).to eql(1)

  end

  it 'handle error receiving dispute payload messages with no payload' do
    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: {
        envelope: {
            channel: "ticket-event",
            addressee: "analyst-console-escalations",
            sender: "talos-intelligence"
        },
        message: {
            dispute: {
                source_type: 'Complaint',
                source_key: 1001,
            }
        }
    }

    # expect(response).to be_error
    dispute = Dispute.where(ticket_source_key: 1001).first
    expect(dispute).to be_nil
  end

  it 'creates disputes for existing customers' do
    vrt_incoming
    guest_company
    existing_customer

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: dispute_message_json

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first
    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(4)
    expect(dispute.dispute_entries.where(ip_address: '64.70.56.99')).to exist
    expect(dispute.dispute_entries.where(ip_address: '184.168.47.225')).to exist
    expect(dispute.dispute_entries.where(uri: '355toyota.com')).to exist
    expect(dispute.dispute_entries.where(uri: 'thepretenders.com')).to exist
  end

  it 'creates disputes for customers with same name different email' do
    vrt_incoming
    guest_company
    FactoryBot.create(:customer, name: customer_name, email: 'not-' + customer_email, company: existing_company)

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: dispute_message_json

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first
    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(4)
    expect(dispute.dispute_entries.where(ip_address: '64.70.56.99')).to exist
    expect(dispute.dispute_entries.where(ip_address: '184.168.47.225')).to exist
    expect(dispute.dispute_entries.where(uri: '355toyota.com')).to exist
    expect(dispute.dispute_entries.where(uri: 'thepretenders.com')).to exist
  end

  it 'should process a duplicate' do



    expect(Dispute).to receive(:is_possible_customer_duplicate?).and_return({:is_dupe => true, :all_resolved => false, :authority => nil})

    vrt_incoming
    guest_company
    FactoryBot.create(:customer, name: customer_name, email: 'not-' + customer_email, company: existing_company)

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: dispute_message_json

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first
    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(4)
    expect(dispute.dispute_entries.where(ip_address: '64.70.56.99')).to exist
    expect(dispute.dispute_entries.where(ip_address: '184.168.47.225')).to exist

    expect(dispute.dispute_entries.where(uri: '355toyota.com')).to exist
    expect(dispute.dispute_entries.where(uri: 'thepretenders.com')).to exist
  end




  it 'should short circuit ticket creation from payload if the ticket already exists (to prevent dupes)' do
    vrt_incoming
    guest_company
    FactoryBot.create(:customer, name: customer_name, email: 'not-' + customer_email, company: existing_company)
    Dispute.create(:ticket_source_key => 1001, :customer_id => Customer.all.first.id, :user_id => User.all.first.id, :status => "NEW")

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: dispute_message_json

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(Dispute.all.size).to eql(1)
    expect(DelayedJob.all.size).to eql(1)

  end

  it 'should close as matching disposition when product is Umbrella with score -6.0 or lower' do

    umbrella_platform = Platform.new
    umbrella_platform.id = 1000
    umbrella_platform.public_name = "Umbrella No Reply"
    umbrella_platform.internal_name = "Umbrella No-Reply"
    umbrella_platform.active = true
    umbrella_platform.webrep = true
    umbrella_platform.webcat = true
    umbrella_platform.filerep = true
    umbrella_platform.emailrep = true
    umbrella_platform.save

    wbrs_response = {"wbrs" => {"score" => -6.0}}

    sbrs_response = {"sbrs" => {"score" => -6.0}}

    expect(Sbrs::Base).to receive(:remote_call_sds_v3).with("355toyota.com", "wbrs").and_return(wbrs_response).at_least(:once)

    expect(Sbrs::ManualSbrs).to receive(:call_sbrs).and_return(sbrs_response).at_least(:once)
    vrt_incoming
    guest_company
    FactoryBot.create(:customer, name: customer_name, email: 'not-' + customer_email, company: existing_company)
    #Dispute.create(:ticket_source_key => 1001, :customer_id => Customer.all.first.id, :user_id => User.all.first.id, :status => "NEW")

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: umbrella_dispute_message_json

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 2001).first

    expect(dispute).to_not be_nil
    expect(Dispute.all.size).to eql(1)
    expect(DelayedJob.all.size).to eql(1)

    expect(dispute.dispute_entries.first.status).to eql("RESOLVED_CLOSED")
    expect(dispute.dispute_entries.first.resolution).to eql("AP - Match")

  end

  it 'should not close as matching disposition when product is Umbrella with score greater than -7.0' do

    umbrella_platform = Platform.new
    umbrella_platform.id = 1000
    umbrella_platform.public_name = "Umbrella No Reply"
    umbrella_platform.internal_name = "Umbrella No-Reply"
    umbrella_platform.active = true
    umbrella_platform.webrep = true
    umbrella_platform.webcat = true
    umbrella_platform.filerep = true
    umbrella_platform.emailrep = true
    umbrella_platform.save

    wbrs_response = {"wbrs" => {"score" => -5.9}}
    sbrs_response = {"sbrs" => {"score" => -5.9}}
    expect(Sbrs::Base).to receive(:remote_call_sds_v3).with("355toyota.com", "wbrs").and_return(wbrs_response).at_least(:once)
    expect(Sbrs::ManualSbrs).to receive(:call_sbrs).and_return(sbrs_response).at_least(:once)
    vrt_incoming
    guest_company
    FactoryBot.create(:customer, name: customer_name, email: 'not-' + customer_email, company: existing_company)
    #Dispute.create(:ticket_source_key => 1001, :customer_id => Customer.all.first.id, :user_id => User.all.first.id, :status => "NEW")

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: umbrella_dispute_message_json

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 2001).first

    expect(dispute).to_not be_nil
    expect(Dispute.all.size).to eql(1)
    expect(DelayedJob.all.size).to eql(1)
    expect(dispute.dispute_entries.first.resolution).to eql("")
    expect(dispute.dispute_entries.first.status).to eql("NEW")

  end

  it 'should close as matching disposition if its an ip address (email) false positive with an sbrs score greater than -1.9' do
    wbrs_response = {"wbrs" => {"score" => -1.0}}

    sbrs_response = {"sbrs" => {"score" => -1.0}}

    expect(Sbrs::Base).to receive(:remote_call_sds_v3).and_return(wbrs_response).at_least(:once)

    expect(Sbrs::ManualSbrs).to receive(:call_sbrs).and_return(sbrs_response).at_least(:once)
    vrt_incoming
    guest_company
    FactoryBot.create(:customer, name: customer_name, email: 'not-' + customer_email, company: existing_company)
    #Dispute.create(:ticket_source_key => 1001, :customer_id => Customer.all.first.id, :user_id => User.all.first.id, :status => "NEW")

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: dispute_message_alt_json_positive

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(Dispute.all.size).to eql(1)
    expect(DelayedJob.all.size).to eql(1)

    expect(dispute.dispute_entries.first.status).to eql("RESOLVED_CLOSED")
    expect(dispute.dispute_entries.first.resolution).to eql("AP - Match")

  end

  it 'should close as matching disposition if its an ip address (email) false negative with an sbrs score less than -2.0' do
    wbrs_response = {"wbrs" => {"score" => -2.1}}

    sbrs_response = {"sbrs" => {"score" => -2.1}}

    expect(Sbrs::Base).to receive(:remote_call_sds_v3).and_return(wbrs_response).at_least(:once)

    expect(Sbrs::ManualSbrs).to receive(:call_sbrs).and_return(sbrs_response).at_least(:once)
    vrt_incoming
    guest_company
    FactoryBot.create(:customer, name: customer_name, email: 'not-' + customer_email, company: existing_company)
    #Dispute.create(:ticket_source_key => 1001, :customer_id => Customer.all.first.id, :user_id => User.all.first.id, :status => "NEW")

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: dispute_message_alt_json_negative

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(Dispute.all.size).to eql(1)
    expect(DelayedJob.all.size).to eql(1)

    expect(dispute.dispute_entries.first.status).to eql("RESOLVED_CLOSED")
    expect(dispute.dispute_entries.first.resolution).to eql("AP - Match")

  end

  it "should filter out ports and strip domains from email addreses submitted as uris/domains'" do

    vrt_incoming
    guest_company
    existing_customer

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: weird_dispute_message_json

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first
    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(3)

    expect(dispute.dispute_entries.where(uri: '355toyota.com/some/path')).to exist
    expect(dispute.dispute_entries.where(uri: 'gmail.com')).to exist
    expect(dispute.dispute_entries.where(uri: 'electric.cars.gov/some/path.php?this=that&that=this')).to exist

  end

  it 'should send a conversion ticket and close as invalid in matching disposition logic when category is blank' do

    Dispute.destroy_all
    DisputeEntry.destroy_all
    DelayedJob.destroy_all
    umbrella_platform = Platform.new
    umbrella_platform.id = 1000
    umbrella_platform.public_name = "Umbrella No Reply"
    umbrella_platform.internal_name = "Umbrella No-Reply"
    umbrella_platform.active = true
    umbrella_platform.webrep = true
    umbrella_platform.webcat = true
    umbrella_platform.filerep = true
    umbrella_platform.emailrep = true
    umbrella_platform.save

    wbrs_response = {"wbrs" => {"score" => 3.5}}

    expect(Sbrs::Base).to receive(:remote_call_sds_v3).with("355toyota.com", "wbrs").and_return(wbrs_response).at_least(:once)

    ReptoolResponse = Struct.new(:status)
    rep_response = ReptoolResponse.new
    rep_response.status = "EXPIRED"

    reptool_response = [rep_response]


    expect(RepApi::Blacklist).to receive(:where).and_return(reptool_response).at_least(:once)
    expect(DisputeEntry).to receive(:get_primary_category).and_return(nil).at_least(:once)
    vrt_incoming
    guest_company
    FactoryBot.create(:customer, name: customer_name, email: 'not-' + customer_email, company: existing_company)
    #Dispute.create(:ticket_source_key => 1001, :customer_id => Customer.all.first.id, :user_id => User.all.first.id, :status => "NEW")

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: non_umbrella_dispute_message_json

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 3001).first

    expect(dispute).to_not be_nil
    expect(Dispute.all.size).to eql(1)

    expect(DelayedJob.all.size).to eql(3)

    expect(dispute.dispute_entries.first.status).to eql("RESOLVED_CLOSED")
    expect(dispute.dispute_entries.first.resolution).to eql("INVALID")

    #expect(dispute.dispute_entries.first.resolution_comment).to eql('Thank you for your request; this has now been forwarded to the team responsible for Web categorization requests. A new Web categorization ticket has been created on your behalf and should be visible in your ticket submission queue. Please see all updates regarding this request on the new ticket.\n\nPlease note that by default, a submission with a Trusted, Favorable, Neutral, or Questionable reputation should be accessible by our customers. Talos does not improve the reputation of already accessible submissions as this would affect the way our automated system functions. If one of our customers cannot access the submission after successful web categorization, that is due to aggressive settings on their side and can only be fixed locally by that customer. If you would like this to be reviewed further, please open a TAC case.\n\nFor future Web categorization requests, please open a Web categorization ticket using the \"Web Categorization Requests\" form: https://talosintelligence.com/reputation_center/support#reputation_center_support_ticket')

  end

  it 'should close as matching disposition when product is not Umbrella' do
    Dispute.destroy_all
    DisputeEntry.destroy_all

    umbrella_platform = Platform.new
    umbrella_platform.id = 1000
    umbrella_platform.public_name = "Umbrella No Reply"
    umbrella_platform.internal_name = "Umbrella No-Reply"
    umbrella_platform.active = true
    umbrella_platform.webrep = true
    umbrella_platform.webcat = true
    umbrella_platform.filerep = true
    umbrella_platform.emailrep = true
    umbrella_platform.save

    wbrs_response = {"wbrs" => {"score" => 3.5}}

    expect(Sbrs::Base).to receive(:remote_call_sds_v3).with("355toyota.com", "wbrs").and_return(wbrs_response).at_least(:once)

    ReptoolResponse = Struct.new(:status)
    rep_response = ReptoolResponse.new
    rep_response.status = "EXPIRED"

    reptool_response = [rep_response]


    expect(RepApi::Blacklist).to receive(:where).and_return(reptool_response).at_least(:once)

    vrt_incoming
    guest_company
    FactoryBot.create(:customer, name: customer_name, email: 'not-' + customer_email, company: existing_company)
    #Dispute.create(:ticket_source_key => 1001, :customer_id => Customer.all.first.id, :user_id => User.all.first.id, :status => "NEW")

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: non_umbrella_dispute_message_json

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 3001).first

    expect(dispute).to_not be_nil
    expect(Dispute.all.size).to eql(1)
    expect(DelayedJob.all.size).to eql(1)

    expect(dispute.dispute_entries.first.status).to eql("RESOLVED_CLOSED")
    expect(dispute.dispute_entries.first.resolution).to eql("UNCHANGED")

  end

  context "non-ascii" do
    let(:dispute_message_cyrillic_json) do
      {
        "envelope": {
          "channel": "ticket-event",
          "addressee": "analyst-console-escalations",
          "sender": "talos-intelligence"
        },
        "message": {
          "dispute": {
            "payload": {
              "name": "Marlin Pierce",
              "email": "marlpier@cisco.com",
              "domain": "cisco.com",
              "problem": "I cannot even read those letters",
              "details": "",
              "user_ip": "::1",
              "ticket_time": "June 15, 2021 16:10",
              "investigate_ips": {},
              "investigate_urls": {
                "липецкаяобласть.рф": {
                  "WBRS_SCORE": "noscore",
                  "WBRS_Rule_Hits": "",
                  "Hostname_ips": "",
                  "rep_sugg": "Untrusted",
                  "category": "Not in our list",
                  "claim": "false negative",
                  "platform": 1
                }
              },
              "email_subject": "I cannot even read those letters",
              "email_body": "____________________________________________________________\nUser-entered\nInformation:\n____________________________________________________________\nTime:\nJune 15, 2021 16:10\nName: Marlin Pierce\nE-mail: marlpier@cisco.com\nDomain:\ncisco.com\nInquiry Type: web\nKey Rules: \nProblem Summary: I cannot even\nread those letters\nIP(s) to be investigated:\n\n\nURI(s) to be investigated:\nлипецкаяобласть.рф\n\nDetailed\nDescriptions:\n\n\n",
              "user_company": "Cisco Systems, Inc.",
              "submission_type": "w"
            },
            "source_key": 101373,
            "source_type": "Dispute"
          }
        }
      }
    end

    it 'receives cyrillic dispute payload messages' do
      vrt_incoming
      guest_company

      post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: dispute_message_cyrillic_json

      expect(response).to be_successful
      dispute = Dispute.where(ticket_source_key: 101373).first

      expect(dispute).to_not be_nil
      expect(dispute.dispute_entries.count).to eq(1)
      
      expect(dispute.dispute_entries.where(uri: 'липецкаяобласть.рф')).to exist
      expect(dispute.ticket_source).to eql("talos-intelligence")
    end
  end
end

# expect(response.code).to be_successful
# expect(response.code).to be_error
# expect(response.code).to be_missing
# expect(response.code).to be_redirect
