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

  let(:mininum_auto_resolve_json) do
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

  it 'receives dispute payload message and does not auto resolve if there are no conditions' do
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

    dispute_entry_1 = DisputeEntry.where(:uri => '355toyota.com').first
    dispute_entry_2 = DisputeEntry.where(:uri => 'thepretenders.com').first

    expect(dispute_entry_1.status).to eql(DisputeEntry::NEW)
    expect(dispute_entry_2.status).to eql(DisputeEntry::NEW)


  end

  it 'receives dispute payload message and does not auto resolve if there is an error' do

  end

  it 'receives dispute payload message and does not auto resolve if umbrella popularity > 0' do

  end

  it 'receives dispute payload message and does not auto resolve if allow list rule from SDS' do

  end

  it 'receives dispute payload message and does not auto resolve if allow list entry in reptool' do

  end

  it 'receives dispute payload message and does not auto resolve if: VT trusted hits is 0, umbrella rating is not bad, total vt hits < 6, and umbrella domain volume is not suspicious' do

  end

  it 'receives dispute payload message and auto resolves if [baseline criteria are met] and VT trusted hits >= 1' do

  end

  it 'receives dispute payload message and auto resolves if [baseline criteria are met] and VT trusted hits < 1 and umbrella rating is bad' do

  end

  it 'receives dispute payload message and auto resolves if [baseline criteria are met] and VT trusted hits < 1 and umbrella rating is not bad and total vt hits >= 6' do

  end

  it 'receives dispute payload message and auto resolves if [baseline criteria are met] and VT trusted hits < 1 and umbrella rating is not bad and total vt hits < 6 and umbrella domain volume is suspicious (auto resolve as Phishing)' do

  end



  ###############################################################################

  xit 'receives dispute payload messages' do
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
  end

  xit 'receives dispute payload message from TI API not in-network' do
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
    expect(dispute.in_network).to eql(nil)
  end

  xit 'creates disputes for existing customers' do
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

  xit 'creates disputes for customers with same name different email' do
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
end

# expect(response.code).to be_successful
# expect(response.code).to be_error
# expect(response.code).to be_missing
# expect(response.code).to be_redirect
