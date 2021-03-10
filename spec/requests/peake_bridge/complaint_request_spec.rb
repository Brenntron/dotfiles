require "rails_helper"

RSpec.describe "Peake-Bridge complaint messages channels", type: :request do
  let(:vrt_incoming) { FactoryBot.create(:vrt_incoming_user) }
  let(:guest_company) { FactoryBot.create(:guest_company) }
  let(:company_name) { 'WRMC' }
  let(:customer_name) { '3-Support Support' }
  let(:customer_email) { 'webmaster@cmim.org' }
  let(:existing_company) { FactoryBot.create(:company, name: company_name) }
  let(:existing_customer) do
    FactoryBot.create(:customer, name: customer_name, email: customer_email, company: existing_company)
  end


  let(:reference_payload) do

    {
        investigate_ips: {
            '72.52.134.84' => {
                "wbrs" => {
                    "WBRS_SCORE"=>"-3.55",
                    "WBRS_Rule_Hits"=>"dotq",
                    "Hostname_ips"=>"",
                    "current_cat"=>"Not in our list",
                    "cat_sugg"=>["Business and Industry"]
                },
                "sbrs" => {
                    "SBRS_SCORE"=>"No score",
                    "SBRS_Rule_Hits"=>"",
                    "Hostname"=>"server-52-84-141-37.yto50.r.cloudfront.net",
                    "current_cat"=>"Not in our list",
                    "cat_sugg"=>["Business and Industry"]
                }
            },
            '72.52.134.51' => {
                "wbrs" => {
                    "WBRS_SCORE"=>"-3.55",
                    "WBRS_Rule_Hits"=>"dotq",
                    "Hostname_ips"=>"",
                    "current_cat"=>"Search Engines and Portals",
                    "cat_sugg"=>["Search Engines and Portals", "Adult"]
                },
                "sbrs"=>{"SBRS_SCORE"=>"No score",
                         "SBRS_Rule_Hits"=>"",
                         "Hostname"=>"redirect-v225.secureserver.net",
                         "current_cat"=>"Search Engines and Portals",
                         "cat_sugg"=>["Search Engines and Portals", "Adult"]
                }
            }
        },
        investigate_urls: {
            'host.gerenciahospitalaria.org' => {
                "WBRS_SCORE"=>"1.55",
                "WBRS_Rule_Hits"=>"alx_cln, suwl",
                "Hostname_ips"=>"",
                "current_cat"=>"Science and Technology",
                "cat_sugg"=>["Science and Technology", "Business and Industry"]
            },
            'thepretenders.com' => {
                "WBRS_SCORE"=>"noscore",
                "WBRS_Rule_Hits"=>"",
                "Hostname_ips"=>"",
                "current_cat"=>"Entertainment",
                "cat_sugg"=>["Entertainment", "Adult"]
            }
        },
        problem: 'What do I need to do to improve the reputation',
        submission_type: 'ew',
        name: 'Ricardo Pedraza',
        email: 'webmaster@cmim.org',
        user_company: 'Guest'
    }
  end
  let(:complaint_params) do
    {
        envelope: {
            channel: "ticket-event",
            addressee: "analyst-console-escalations",
            sender: "talos-intelligence"
        },
        message: {
            complaint: {
                source_type: 'Complaint',
                source_key: 1001,
                payload: complaint_payload
            }
        }
    }
  end
  let(:bridge_message) { double('Bridge::BaseMessage', post: true) }
  ###############################################################################################


  let(:complaint_message_json) do
    {
        envelope: {
            channel: "ticket-event",
            addressee: "analyst-console-escalations",
            sender: "talos-intelligence"
        },
        message: {
            complaint: {
                source_type: 'Complaint',
                source_key: 1001,
                payload: {
                    investigate_ips: {
                    },
                    investigate_urls: {
                        "355toyota.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "current_cat"=>"Science and Technology",
                            "cat_sugg"=>["Science and Technology", "Business and Industry"]
                        },
                        "thepretenders.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "current_cat"=>"Science and Technology",
                            "cat_sugg"=>["Science and Technology", "Business and Industry"]
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
            complaint: {
                source_type: 'Complaint',
                source_key: 1001,
                payload: {
                    investigate_ips: {

                    },
                    investigate_urls: {
                        "355toyota.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "current_cat"=>"Search Engines and Portals",
                            "cat_sugg"=>["Search Engines and Portals", "Adult"]
                        },
                        "thepretenders.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "current_cat"=>"Search Engines and Portals",
                            "cat_sugg"=>["Search Engines and Portals", "Adult"]
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
                    product_platform: "test_platform",
                    product_version: "test_platform_version",
                    network: false
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
            complaint: {
                source_type: 'Complaint',
                source_key: 1001,
                payload: {
                    investigate_ips: {
                    },
                    investigate_urls: {
                        "355toyota.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "current_cat"=>"Science and Technology",
                            "cat_sugg"=>["Science and Technology", "Business and Industry"]
                        },
                        "thepretenders.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"",
                            "Hostname_ips"=>"",
                            "current_cat"=>"Science and Technology",
                            "cat_sugg"=>["Science and Technology", "Business and Industry"]
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
                    product_platform: "test_platform",
                    product_version: "test_platform_version",
                    network: true

                }
            }
        }
    }

  end



  ################################################################################################

  it 'receives complaint payload messages' do
    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: complaint_message_json

    expect(response).to be_successful
    complaint = Complaint.where(ticket_source_key: 1001).first

    expect(complaint).to_not be_nil
    expect(complaint.complaint_entries.count).to eq(2)
    expect(complaint.complaint_entries.where(uri: '355toyota.com')).to exist
    expect(complaint.complaint_entries.where(uri: 'thepretenders.com')).to exist
  end

  it 'receives dispute payload message from TI API not in-network' do
    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: ti_api_message_json_non_network

    expect(response).to be_successful
    complaint = Complaint.where(ticket_source_key: 1001).first

    expect(complaint).to_not be_nil
    expect(complaint.complaint_entries.count).to eq(2)
    expect(complaint.complaint_entries.where(uri: '355toyota.com')).to exist
    expect(complaint.complaint_entries.where(uri: 'thepretenders.com')).to exist
    expect(complaint.product_platform).to eql("test_platform")
    expect(complaint.product_version).to eql("test_platform_version")
    expect(complaint.in_network).to eql(nil)
  end

  it 'receives dispute payload message from TI API in-network' do
    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: ti_api_message_json_in_network

    expect(response).to be_successful
    complaint = Complaint.where(ticket_source_key: 1001).first

    expect(complaint).to_not be_nil
    expect(complaint.complaint_entries.count).to eq(2)
    expect(complaint.complaint_entries.where(uri: '355toyota.com')).to exist
    expect(complaint.complaint_entries.where(uri: 'thepretenders.com')).to exist
    expect(complaint.product_platform).to eql("test_platform")
    expect(complaint.product_version).to eql("test_platform_version")
    expect(complaint.in_network).to eql(true)
    expect(complaint.complaint_entries.first.internal_comment).to include("Complaint is [in network], IPS bugzilla bug created. Reference Bugzilla ID: #{ResearchBug.all.first.id}" )
    expect(complaint.complaint_entries.last.internal_comment).to include("Complaint is [in network], IPS bugzilla bug created. Reference Bugzilla ID: #{ResearchBug.all.first.id}" )

    expect(ResearchBug.all.size).to eql(1)

  end

  it 'handle error receiving complaint payload messages with no payload' do
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
    complaint = Complaint.where(ticket_source_key: 1001).first
    expect(complaint).to be_nil
  end


  it 'should short circuit ticket creation from payload if the ticket already exists (to prevent dupes)' do
    vrt_incoming
    guest_company
    FactoryBot.create(:customer, name: customer_name, email: 'not-' + customer_email, company: existing_company)
    Complaint.create(:ticket_source_key => 1001, :customer_id => Customer.all.first.id, :status => "NEW")

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: complaint_message_json

    expect(response).to be_successful
    complaint = Complaint.where(ticket_source_key: 1001).first

    expect(complaint).to_not be_nil
    expect(Complaint.all.size).to eql(1)
    expect(DelayedJob.all.size).to eql(1)
  end


end

# expect(response.code).to be_successful
# expect(response.code).to be_error
# expect(response.code).to be_missing
# expect(response.code).to be_redirect
