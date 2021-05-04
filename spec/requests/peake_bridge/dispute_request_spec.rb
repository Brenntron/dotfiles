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


end

# expect(response.code).to be_successful
# expect(response.code).to be_error
# expect(response.code).to be_missing
# expect(response.code).to be_redirect
