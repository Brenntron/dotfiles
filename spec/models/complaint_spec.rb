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
                "category_id" => 5,
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
  let(:certainty_response) { double('HTTPI::Response', code: 200, body: [].to_json) }
  let(:bug_factory) do
    double('Bugzilla::Bug', create: { "id" => 101 })
  end

  before(:example) do
    FactoryBot.create(:vrt_incoming_user)
    FactoryBot.create(:guest_company)
  end

  it 'processes bridge payload' do
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
        .to receive(:post_request)
                .with(path: '/v1/wbrsrulelib/cat/rules', body: anything)
                .and_return(certainty_response)
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
    bugzilla_rest_session = BugzillaRest::Session.default_session
    expect(bugzilla_rest_session).to receive(:create_bug).and_return(bugzilla_rest_session.build_bug(id: 1001))
    complaint_message_payload[:bugzilla_rest_session] = bugzilla_rest_session

    expect do
      Complaint.process_bridge_payload(complaint_message_payload)
    end.to change { Complaint.count }.from(0).to(1)
  end

  it 'check to ensure WBRS score is populated' do
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
        .to receive(:post_request)
                .with(path: '/v1/wbrsrulelib/cat/rules', body: anything)
                .and_return(certainty_response)
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
    bugzilla_rest_session = BugzillaRest::Session.default_session
    expect(bugzilla_rest_session).to receive(:create_bug).and_return(bugzilla_rest_session.build_bug(id: 1001))
    complaint_message_payload[:bugzilla_rest_session] = bugzilla_rest_session

    expect do
      Complaint.process_bridge_payload(complaint_message_payload)
    end.to change { Complaint.count }.from(0).to(1)
    expect(ComplaintEntry.first.wbrs_score).to eq(1.58)
  end

  it 'check parsing urls' do
    parse = Complaint.parse_url('2e6b5fd9344d4f8565e7d015d861b240.europe-west3.gcp.cloud.es.io/test/go')
    expect(parse[:subdomain]).to eq('2e6b5fd9344d4f8565e7d015d861b240.europe-west3.gcp.cloud')
    expect(parse[:domain]).to eq('es.io')
    expect(parse[:path]).to eq('/test/go')
  end

  it "should create convert messages to disputes" do
    current_user = FactoryBot.create(:current_user)
    customer = FactoryBot.create(:customer, name: 'Some Customer')
    complaint = Complaint.create(:ticket_source_key => 1001, :customer_id => Customer.all.first.id, :status => "NEW")

    new_complaint_entry = ComplaintEntry.new
    new_complaint_entry.complaint_id = complaint.id
    new_complaint_entry.user_id = current_user.id
    new_complaint_entry.uri = "www.google.com"
    new_complaint_entry.entry_type = "URI/DOMAIN"
    new_complaint_entry.wbrs_score = nil
    new_complaint_entry.suggested_disposition = "Search Engines and Portals"
    new_complaint_entry.url_primary_category = "Search Engines and Portals"
    new_complaint_entry.subdomain = "www"
    new_complaint_entry.domain = "test.com"
    new_complaint_entry.path = nil
    new_complaint_entry.status = ComplaintEntry::NEW
    new_complaint_entry.is_important = 0
    new_complaint_entry.save

    new_complaint_entry2 = ComplaintEntry.new
    new_complaint_entry2.complaint_id = complaint.id
    new_complaint_entry2.user_id = current_user.id
    new_complaint_entry2.uri = "www.malware.com"
    new_complaint_entry2.entry_type = "URI/DOMAIN"
    new_complaint_entry2.wbrs_score = nil
    new_complaint_entry2.suggested_disposition = "Search Engines and Portals"
    new_complaint_entry2.url_primary_category = "Search Engines and Portals"
    new_complaint_entry2.subdomain = "www"
    new_complaint_entry2.domain = "test.com"
    new_complaint_entry2.path = nil
    new_complaint_entry2.status = ComplaintEntry::NEW
    new_complaint_entry2.is_important = 0
    new_complaint_entry2.save

    params = {}

    params[:complaint_id] = 1
    params[:submission_type] = "w"
    params[:summary] = "test_summary"

    params[:suggested_dispositions] = [{:entry => 'www.google.com', :suggested_disposition => 'fp'},{:entry => 'www.malware.com', :suggested_disposition => 'fn'}]


  end

end
