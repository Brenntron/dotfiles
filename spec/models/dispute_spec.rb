describe Dispute do
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
  let(:dispute_message_payload) do
    ActionController::Parameters.new(
        {
            payload: {
                'name' => "Marlin Pierce",
                'email' => "marlpier@cisco.com",
                'domain' => "cisco.com",
                'problem' => "New category",
                'details' => '',
                'user_ip' => "::1",
                'ticket_time' => "September 03, 2018 12:04",
                'investigate_ips' => {},
                'investigate_urls' => {
                    'www.spanx.com' => {
                        'WBRS_SCORE' => '1.58',
                        'WBRS_Rule_Hits' => "alx_cln, vsvd",
                        'Hostname_ips' => '',
                        'rep_sugg' => "Good",
                        'category' => "Shopping"

                    }
                },
                'email_subject' => "New category",
                'email_body' => dispute_email,
                'user_company' => "Cisco Systems, Inc.",
                'submission_type' => "w"
            },
            source_key: 47,
            source_type: "Dispute"
    })
  end
  let(:top_url_response_json) do
    {
        "www.spanx.com": true
    }.to_json
  end
  let(:blacklist_json) do
    {
        'www.spanx.com' => 'NOT_FOUND'
    }.to_json
  end
  let(:top_url_response_response) { double('HTTPI::Response', code: 200, body: top_url_response_json) }
  let(:blacklist_response) { double('HTTPI::Response', code: 200, body: blacklist_json) }
  let(:bug_factory) do
    double('Bugzilla::Bug', create: { "id" => 101 })
  end

  before(:example) do
    FactoryBot.create(:vrt_incoming_user)
    FactoryBot.create(:guest_company)
  end

  it 'processes bridge payload' do
    allow(Bugzilla::Bug).to receive(:new).and_return(bug_factory)
    allow(Wbrs::Base)
        .to receive(:call_json_request)
                .with(:post, '/v1/cat/urls/top', body: anything)
                .and_return(top_url_response_response)
    allow(RepApi::Base)
        .to receive(:call_json_request)
                .with(:post, '/blacklist/get', body: anything)
                .and_return(blacklist_response)

    expect do
      Dispute.process_bridge_payload(dispute_message_payload)
    end.to change { Dispute.count }.from(0).to(1)
  end
end
