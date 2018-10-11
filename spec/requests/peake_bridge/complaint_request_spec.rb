require "rails_helper"

RSpec.describe "Peake-Bridge messages miscellanious channels", type: :request do
  let(:vrt_incoming) { FactoryBot.create(:vrt_incoming_user) }
  let(:guest_company) { FactoryBot.create(:guest_company) }

  it 'receives complaint payload messages' do
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
                payload: {
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
            }
        }
    }

    expect(response).to be_success
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
end

# expect(response.code).to be_success
# expect(response.code).to be_error
# expect(response.code).to be_missing
# expect(response.code).to be_redirect
