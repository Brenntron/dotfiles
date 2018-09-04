describe Wbrs::RuleLink do
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
                "mnem": "art",

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
            "limit": "1000",
            "rows_found": 1
        }
    }.to_json
  end
  let(:rule_links_error_json) {'{"Error": "No search criteria provided"}'}
  let(:rule_links_response) { double('HTTPI::Response', code: 200, body: rule_links_json) }
  let(:rule_links_error) { double('HTTPI::Response', code: 400, body: rule_links_error_json) }



  ### TESTS ####################################################################

  it 'should get rule links given conditions' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(rule_links_response)

    rule_links = Wbrs::RuleLink.where(category_ids: [6], active: true)

    expect(rule_links.count).to eql(2)
    expect(rule_links.first.prefix_id).to eql(101)
  end

  it 'should handle errors when getting rule links given conditions' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(rule_links_error)

    expect {
      Wbrs::RuleLink.where
    }.to raise_error(Wbrs::WbrsError)

  end

end
