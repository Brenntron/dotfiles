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


  let(:complaint_payload) do
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

  it 'receives complaint payload messages' do
    vrt_incoming
    guest_company
    expect(Bridge::ComplaintCreatedEvent).to receive(:new).and_return(bridge_message)
    expect(Customer).to receive(:process_and_get_customer).and_return(FactoryBot.create(:customer))
    allow(ComplaintEntryPreload).to receive(:generate_preload_from_complaint_entry).and_return(true)
    bugzilla_rest_session = BugzillaRest::Session.default_session
    expect(bugzilla_rest_session).to receive(:create_bug).and_return(bugzilla_rest_session.build_bug(id: 1001))

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: complaint_params

    expect(response).to be_successful
    complaint = Complaint.where(ticket_source_key: 1001).first
    expect(complaint).to_not be_nil
    expect(complaint.complaint_entries.count).to eq(4)
    expect(complaint.complaint_entries.where(ip_address: '72.52.134.84')).to exist
    expect(complaint.complaint_entries.where(ip_address: '72.52.134.51')).to exist
    expect(complaint.complaint_entries.where(uri: 'host.gerenciahospitalaria.org')).to exist
    expect(complaint.complaint_entries.where(uri: 'thepretenders.com')).to exist
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
            complaint: {
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
