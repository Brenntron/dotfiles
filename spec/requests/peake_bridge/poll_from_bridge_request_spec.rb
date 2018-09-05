require "rails_helper"

RSpec.describe "Talos Intelligence poll-from-bridge channel", type: :request do
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
  let(:complaint_message) do
    {
        envelope: {
            channel: "ticket-event",
            addressee: "analyst-console-escalations",
            sender: "talos-intelligence"
        },
        message: {
            complaint: {
                source_key: 49,
                source_type: "Complaint",
                payload: {
                    name: "Marlin Pierce",
                    email: "marlpier@cisco.com",
                    domain: "cisco.com",
                    problem: "New category",
                    details: '',
                    user_ip: "::1",
                    ticket_time: "September 03, 2018 12:05",
                    investigate_ips: {},
                    investigate_urls: {
                        "www.spanx.com": {
                            WBRS_SCORE: '1.58',
                            WBRS_Rule_Hits: "alx_cln, vsvd",
                            Hostname_ips: '',
                            current_cat: "Shopping",
                            cat_sugg: [
                                "Lingerie and Swimsuits"
                            ],
                        }
                    },
                    user_company: "Cisco Systems, Inc.",
                    submission_type: "w"
                }
            }
        }
    }
  end
  let(:dispute_message) do
    {
        envelope: {
            channel: "ticket-event",
            addressee: "analyst-console-escalations",
            sender: "talos-intelligence"
        },
        message: {
            dispute: {
                payload: {
                    name: "Marlin Pierce",
                    email: "marlpier@cisco.com",
                    domain: "cisco.com",
                    problem: "New category",
                    details: '',
                    user_ip: "::1",
                    ticket_time: "September 03, 2018 12:04",
                    investigate_ips: {},
                    investigate_urls: {
                        "www.spanx.com": {
                            WBRS_SCORE: '1.58',
                            WBRS_Rule_Hits: "alx_cln, vsvd",
                            Hostname_ips: '',
                            rep_sugg: "Good",
                            category: "Shopping"

                        }
                    },
                    email_subject: "New category",
                    email_body: dispute_email,
                    user_company: "Cisco Systems, Inc.",
                    submission_type: "w"
                },
                source_key: 47,
                source_type: "Dispute"
            }
        }
    }
  end

  it 'receives a complaint message' do

    post '/escalations/peake_bridge/channels/ticket-event/messages', headers: { 'Content-Type': 'application/json' },
         params: complaint_message.to_json

    expect(response.code).to eq('200')
  end

  it 'receives a dispute message' do

    post '/escalations/peake_bridge/channels/ticket-event/messages', headers: { 'Content-Type': 'application/json' },
         params: dispute_message.to_json

    expect(response.code).to eq('200')
  end
end
