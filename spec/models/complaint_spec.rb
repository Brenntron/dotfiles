describe Complaint do
  let(:complaint_message_payload) do
    ActionController::Parameters.new({
        'source_key' => 49,
        'source_type' => "Complaint",
        'payload' => {
            'name' => "Marlin Pierce",
            'email' => "marlpier@cisco.com",
            'domain' => "cisco.com",
            'problem' => "New category",
            'details' => '',
            'user_ip' => "::1",
            'ticket_time' => "September 03, 2018 12:05",
            'investigate_ips' => {},
            'investigate_urls' => {
                'www.spanx.com' => {
                    'WBRS_SCORE' => '1.58',
                    'WBRS_Rule_Hits' => "alx_cln, vsvd",
                    'Hostname_ips' => '',
                    'current_cat' => "Shopping",
                    'cat_sugg' => [
                        "Lingerie and Swimsuits"
                    ],
                }
            },
            'user_company' => "Cisco Systems, Inc.",
            'submission_type' => "w"
        }
    })
  end
  let(:rules_get_json) do
    {
        "data" => [],
        "errors" => [],
        "meta" => {
            "limit" => 1000,
            "rows_found" => 0
        }
    }.to_json
  end
  let(:top_url_response_json) do
    {
        "www.spanx.com": true
    }.to_json
  end
  let(:rules_get_response) { double('HTTPI::Response', code: 200, body: rules_get_json) }
  let(:top_url_response_response) { double('HTTPI::Response', code: 200, body: top_url_response_json) }
  let(:bug_factory) do
    double('Bugzilla::Bug', create: { "id" => 101 })
  end

  before(:example) do
    FactoryBot.create(:vrt_incoming_user)
    FactoryBot.create(:guest_company)
  end

  it 'processes bridge payload' do
    allow(Bugzilla::Bug).to receive(:new).and_return(bug_factory)
    # Note: get rules is called three times.
    # Note: had get rules returned results, another call to get the history would have been made.
    allow(Wbrs::Base)
        .to receive(:post_request)
                .with(path: '/v1/cat/rules/get', body: anything)
                .and_return(rules_get_response)
    allow(Wbrs::Base)
        .to receive(:call_json_request)
                .with(:post, '/v1/cat/urls/top', body: anything)
                .and_return(top_url_response_response)
    allow(CapybaraSpider).to receive(:low_capture).and_return('')
    allow(Bridge::ComplaintCreatedEvent).to receive(:new).and_return(double('Bridge::ComplaintCreatedEvent', post: nil))

    expect do
      Complaint.process_bridge_payload(complaint_message_payload)
    end.to change { Complaint.count }.from(0).to(1)
  end
end
