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
        "data" => [
            {
                "category" => 5,
                "desc_long" => "Auctions; bartering; online purchasing; coupons and free offers; yellow pages; classified ads; general office supplies; online catalogs; online malls.",
                "descr" => "Shopping",
                "mnem" => "shop",
                "domain" => "spanx.com",
                "is_active" => 1,
                "path" => "",
                "path_hashed" => "",
                "port" => 0,
                "prefix_id" => 2,
                "protocol" => "http",
                "subdomain" => "",
                "truncated" => 0
            }
        ],
        "errors" => [],
        "meta" => {
            "limit" => 1000,
            "rows_found" => 1
        }
    }.to_json
  end
  let(:audit_json) do
    {
        "data" => [
            {
                "action" => "insert",
                "category_id" => 5,
                "confidence" => 1,
                "description" => "",
                "event_id" => 1,
                "prefix_id" => 1,
                "time" => "Tue, 20 Mar 2018 14:44:05 GMT",
                "user" => "tester333"
            },
            {
                "action" => "update",
                "category_id" => 5,
                "confidence" => 1,
                "description" => "",
                "event_id" => 2,
                "prefix_id" => 1,
                "time" => "Tue, 20 Mar 2018 14:56:28 GMT",
                "user" => "tester"
            }
        ],
        "meta" => {
            "limit" => 1000,
            "rows_found" => 2
        }
    }.to_json
  end
  let(:categories_json) do
    {
        "data": [
            {
                "category": 5,
                "desc_long": "Auctions; bartering; online purchasing; coupons and free offers; yellow pages; classified ads; general office supplies; online catalogs; online malls.",
                "descr": "Shopping",
                "mnem": "shop"
            }
        ]
    }.to_json
  end
  let(:top_url_response_json) do
    {
        "www.spanx.com": true
    }.to_json
  end
  let(:rules_get_response) { double('HTTPI::Response', code: 200, body: rules_get_json) }
  let(:audit_response) { double('HTTPI::Response', code: 200, body: audit_json) }
  let(:categories_response) { double('HTTPI::Response', code: 200, body: categories_json) }
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
        .to receive(:post_request)
                .with(path: '/v1/cat/rules/audit', body: anything)
                .and_return(audit_response)
    allow(Wbrs::Base)
        .to receive(:call_json_request)
                .with(:get, '/v1/cat/categories', body: anything)
                .and_return(categories_response)
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

  it 'check to ensure WBRS score is populated' do
    allow(Bugzilla::Bug).to receive(:new).and_return(bug_factory)
    # Note: get rules is called three times.
    # Note: had get rules returned results, another call to get the history would have been made.
    allow(Wbrs::Base)
        .to receive(:post_request)
                .with(path: '/v1/cat/rules/get', body: anything)
                .and_return(rules_get_response)
    allow(Wbrs::Base)
        .to receive(:post_request)
                .with(path: '/v1/cat/rules/audit', body: anything)
                .and_return(audit_response)
    allow(Wbrs::Base)
        .to receive(:call_json_request)
                .with(:get, '/v1/cat/categories', body: anything)
                .and_return(categories_response)
    allow(Wbrs::Base)
        .to receive(:call_json_request)
                .with(:post, '/v1/cat/urls/top', body: anything)
                .and_return(top_url_response_response)
    allow(CapybaraSpider).to receive(:low_capture).and_return('')
    allow(Bridge::ComplaintCreatedEvent).to receive(:new).and_return(double('Bridge::ComplaintCreatedEvent', post: nil))

    Complaint.process_bridge_payload(complaint_message_payload)
    expect(ComplaintEntry.first.wbrs_score).to eq(1.58)
  end
end
