describe Wbrs::Prefix do
  let(:prefix_json) do
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
  let(:no_rule_link_json) do
    {
        "data": [],
        "errors": [],
        "meta": {
            "limit": "1",
            "rows_found": 1
        }
    }.to_json
  end
  let(:prefix_error_json) {{'Error' => 'No search criteria provided.'}.to_json}
  let(:prefix_response) { double('HTTPI::Response', code: 200, body: prefix_json) }
  let(:prefix_error) { double('HTTPI::Response', code: 400, body: prefix_error_json) }
  let(:one_rule_link_response) { double('HTTPI::Response', code: 200, body: one_rule_link_json) }
  let(:no_rule_link_response) { double('HTTPI::Response', code: 200, body: no_rule_link_json) }



  ### TESTS ####################################################################

  it 'should find a prefix' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(one_rule_link_response)

    prefix = Wbrs::Prefix.find(101)

    expect(prefix).to be_a_kind_of(Wbrs::Prefix)
    expect(prefix.id).to eq(101)
  end

  it 'should return nil from find no prefix' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(no_rule_link_response)

    prefix = Wbrs::Prefix.find(101)

    expect(prefix).to be_nil
  end

  it 'should handle errors finding a prefix' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(prefix_error)

    expect {
      prefix = Wbrs::Prefix.find(101)
    }.to raise_error(RuntimeError)

  end

  it 'should get a prefixes collection given conditions' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(prefix_response)

    prefixes = Wbrs::Prefix.where(category_ids: [5, 6], active: true).sort_by{ |prefix| prefix.id }

    expect(prefixes.count).to eq(2)
    expect(prefixes[0].id).to eq(101)
    expect(prefixes[1].id).to eq(102)
  end

  it 'should handle errors getting a prefixes collection given conditions' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(prefix_error)

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
