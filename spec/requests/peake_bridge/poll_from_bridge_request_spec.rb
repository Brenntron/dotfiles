require "rails_helper"

RSpec.describe "Talos Intelligence poll-from-bridge channel", type: :request do

  let(:vrt_incoming) { FactoryBot.create(:vrt_incoming_user) }
  let(:guest_company) { FactoryBot.create(:guest_company) }
  let(:company_name) { 'WRMC' }
  let(:customer_name) { '3-Support Support' }
  let(:customer_email) { 'webmaster@cmim.org' }
  let(:existing_company) { FactoryBot.create(:company, name: company_name) }
  let(:existing_customer) do
    FactoryBot.create(:customer, name: customer_name, email: customer_email, company: existing_company)
  end

  let(:dispute_email) do
    <<-HEREDOC
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


  let(:bridge_message_non_auto_resolve) do
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
                source: 'talos-intelligence',
                payload: {
                    investigate_ips: {
                        "64.70.56.99" => {
                            "wbrs" => {
                                "WBRS_SCORE"=>"-1.00",
                                "WBRS_Rule_Hits"=>"dotq, suph, wsku",
                                "Hostname_ips"=>"",
                                "rep_sugg"=>"Good",
                                "category"=>"Not in our list"
                            },
                            "sbrs" => {
                                "SBRS_SCORE"=>"-1.00",
                                "SBRS_Rule_Hits"=>"dotq, suph, wsku",
                                "Hostname"=>"www.dealer.com",
                                "rep_sugg"=>"Good",
                                "category"=>"Not in our list"
                            }
                        },
                        "184.168.47.225"=>{
                            "wbrs" => {
                                "WBRS_SCORE"=>"-1.00",
                                "WBRS_Rule_Hits"=>"dotq, suph, wsku",
                                "Hostname_ips"=>"",
                                "rep_sugg"=>"Good",
                                "category"=>"Search Engines and Portals"
                            },
                            "sbrs" => {
                                "SBRS_SCORE"=>"-1.00",
                                "SBRS_Rule_Hits"=>"dotq, suph, wsku",
                                "Hostname"=>"redirect-v225.secureserver.net",
                                "rep_sugg"=>"Good",
                                "category"=>"Search Engines and Portals"
                            }
                        }
                    },
                    investigate_urls: {
                        "355toyota.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"dotq, suph, wsku",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Good",
                            "category"=>"Not in our list"
                        },
                        "thepretenders.com" => {
                            "WBRS_SCORE"=>"noscore",
                            "WBRS_Rule_Hits"=>"dotq, suph, wsku",
                            "Hostname_ips"=>"",
                            "rep_sugg"=>"Good",
                            "category"=>"Entertainment"
                        }
                    },
                    problem: 'What do I need to do to improve the reputation',
                    submission_type: 'w',
                    name: customer_name,
                    user_company: company_name,
                    email: 'webmaster@cmim.org',
                    email_subject: 'Now AC is ready, 355 Toyota and The Pretenders reputation dispute.',
                    email_body: dispute_email,
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




  before(:each) do
    Platform.destroy_all
    Company.destroy_all
    Customer.destroy_all
    DisputeEntryPreload.destroy_all
    DisputeComment.destroy_all
    DisputeEntry.destroy_all
    ComplaintEntry.destroy_all
    DisputeEmail.destroy_all
    DisputeRuleHit.destroy_all
    Dispute.destroy_all
    Complaint.destroy_all
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
    Company.destroy_all
    Customer.destroy_all
    DisputeEntryPreload.destroy_all
    DisputeComment.destroy_all
    DisputeEntry.destroy_all
    ComplaintEntry.destroy_all
    DisputeEmail.destroy_all
    DisputeRuleHit.destroy_all
    Dispute.destroy_all
    Complaint.destroy_all
    DelayedJob.destroy_all
  end

  it 'receives a dispute message and creates a complaint record with all relevant records successfully (non auto resolve)' do

    vrt_incoming
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: bridge_message_non_auto_resolve

    expect(response).to be_successful
    dispute = Dispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(dispute.dispute_entries.count).to eq(4)
    expect(dispute.dispute_entries.where(ip_address: '64.70.56.99')).to exist
    expect(dispute.dispute_entries.where(ip_address: '184.168.47.225')).to exist
    expect(dispute.dispute_entries.where(uri: '355toyota.com')).to exist
    expect(dispute.dispute_entries.where(uri: 'thepretenders.com')).to exist
    expect(dispute.ticket_source).to eql("talos-intelligence")

    expect(DisputeRuleHit.all.size).to eql(18)
    expect(DelayedJob.all.size).to eql(1)
    expect(DisputeEmail.all.size).to eql(1)
    expect(DisputeComment.all.size).to eql(0)
    expect(DisputeEntryPreload.all.size).to eql(4)

    expect(dispute.platform_id).to eql(1001)
    expect(dispute.product_platform).to eql(nil)



  end


  xit 'receives a complaint message and creates a complaint record with all relevant records successfully' do

    post '/escalations/peake_bridge/channels/ticket-event/messages', headers: { 'Content-Type': 'application/json' },
         params: complaint_message.to_json

    expect(response.code).to eq('200')
  end


end
