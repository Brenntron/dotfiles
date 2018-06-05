describe Wbrs::Prefix do
  let(:rule_links_json) do
    {
        "data": [
            {
                "category": 5,
                "desc_long": "Education-related sites and web pages such as schools, colleges, universities, teaching materials, teachers resources; technical and vocational training; online training; education issues and policies;  financial aid; school funding; standards and testing.",
                "descr": "Education",
                "mnem": "edu",

                "prefix_id": 101,
                "domain": "example.net",
                "is_active": false,
                "path": "",
                "path_hashed": "",
                "port": 0,
                "protocol": "https",
                "subdomain": "",
                "truncated": false
            },
            {
                "category": 6,
                "desc_long": "Galleries and exhibitions; artists and art; photography; literature and books; performing arts and theater; musicals; ballet; museums; design; architecture.  Cinema and television are classified as Entertainment.",
                "descr": "Arts",
                "mnem": "category",

                "prefix_id": 101,
                "domain": "example.net",
                "is_active": false,
                "path": "",
                "path_hashed": "",
                "port": 0,
                "protocol": "https",
                "subdomain": "",
                "truncated": false
            },
            {
                "category": 6,
                "desc_long": "Galleries and exhibitions; artists and art; photography; literature and books; performing arts and theater; musicals; ballet; museums; design; architecture.  Cinema and television are classified as Entertainment.",
                "descr": "Arts",
                "mnem": "category",

                "prefix_id": 102,
                "domain": "example.net",
                "is_active": false,
                "path": "",
                "path_hashed": "",
                "port": 0,
                "protocol": "https",
                "subdomain": "",
                "truncated": false
            }
        ],
        "errors": [],
        "meta": {
            "limit": "1000",
            "rows_found": 3
        }
    }.to_json
  end
  let(:one_rule_link_json) do
    {
        "data": [
            {
                "category": 6,
                "desc_long": "Galleries and exhibitions; artists and art; photography; literature and books; performing arts and theater; musicals; ballet; museums; design; architecture.  Cinema and television are classified as Entertainment.",
                "descr": "Arts",
                "mnem": "category",

                "prefix_id": 101,
                "domain": "example.net",
                "is_active": false,
                "path": "",
                "path_hashed": "",
                "port": 0,
                "protocol": "https",
                "subdomain": "",
                "truncated": false
            }
        ],
        "errors": [],
        "meta": {
            "limit": "1",
            "rows_found": 1
        }
    }.to_json
  end
  let(:rule_links_error_json) {{'Error' => 'No search criteria provided.'}.to_json}
  let(:rule_links_response) { double('HTTPI::Response', code: 200, body: rule_links_json) }
  let(:rule_links_error) { double('HTTPI::Response', code: 400, body: rule_links_error_json) }



  ### TESTS ####################################################################

  it 'should find a prefix'

  it 'should get a prefixes collection given conditions' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(rule_links_response)

    prefixes = Wbrs::Prefix.where(category_ids: [5, 6], active: true).sort_by{ |prefix| prefix.id }

    # expect(prefixes).to eq(nil)
    expect(prefixes.count).to eq(2)
    expect(prefixes[0].id).to eq(101)
    expect(prefixes[1].id).to eq(102)
  end

  it 'should handle errors getting a prefixes collection given conditions' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(rule_links_error)

    expect {
      Wbrs::Prefix.where
    }.to raise_error(RuntimeError)

  end

  it 'should disable a list of prefixes'

end

describe 'A prefix' do

  it 'should add a prefix categorization'

  it 'should edit its categories'

  it 'should get a history'

end
