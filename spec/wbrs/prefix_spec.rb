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
            },
            {
                "category": 6,
                "desc_long": "Galleries and exhibitions; artists and art; photography; literature and books; performing arts and theater; musicals; ballet; museums; design; architecture.  Cinema and television are classified as Entertainment.",
                "descr": "Arts",
                "mnem": "art",

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
  let(:prefix_error_json) {'{"Error": "No search criteria provided"}'}
  let(:create_prefix_json) { {"Created": 111}.to_json }
  let(:create_prefix_error_json) {{'Error' => 'Prefix ID required.'}.to_json}
  let(:prefix_response) { double('HTTPI::Response', code: 200, body: prefix_json) }
  let(:prefix_error) { double('HTTPI::Response', code: 400, body: prefix_error_json) }
  let(:one_rule_link_response) { double('HTTPI::Response', code: 200, body: one_rule_link_json) }
  let(:no_rule_link_response) { double('HTTPI::Response', code: 200, body: no_rule_link_json) }
  let(:create_prefix_response) { double('HTTPI::Response', code: 200, body: create_prefix_json) }
  let(:create_prefix_error) { double('HTTPI::Response', code: 400, body: create_prefix_error_json) }
  let(:category) { Wbrs::Category.new_from_datum('category' => 5, 'desc_long' => 'long', 'descr' => 'short', 'mnem' => 'cat5') }



  ### TESTS ####################################################################

  it 'should find a prefix' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(one_rule_link_response)

    prefix = Wbrs::Prefix.find(101)

    expect(prefix).to be_a_kind_of(Wbrs::Prefix)
    expect(prefix.id).to eql(101)
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
    }.to raise_error(Wbrs::WbrsError)

  end

  it 'should get a prefixes collection given conditions' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(prefix_response)

    prefixes = Wbrs::Prefix.where(category_ids: [5, 6], active: true).sort_by{ |prefix| prefix.id }

    expect(prefixes.count).to eql(2)
    expect(prefixes[0].id).to eql(101)
    expect(prefixes[1].id).to eql(102)
  end

  it 'should handle errors getting a prefixes collection given conditions' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(prefix_error)

    expect {
      Wbrs::Prefix.where
    }.to raise_error(Wbrs::WbrsError)

  end

  it 'should add a prefix categorization' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(create_prefix_response)

    creation_prefix_id =
        Wbrs::Prefix.create_from_url(url: "http://ukr12.net",
                                     categories: [category, 6],
                                     user: 'tester',
                                     description: 'Testing /add route.')

    expect(creation_prefix_id).to eql(111)
  end


  it 'should handle errors adding a prefix categorization' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(create_prefix_error)

    expect {
      Wbrs::Prefix.create_from_url(url: "http://ukr12.net",
                                   user: 'tester',
                                   description: 'Testing /add route.')
    }.to raise_error(Wbrs::WbrsError)

  end

end

describe 'A prefix' do
  let(:all_categories) do
    [
        Wbrs::Category.new_from_datum("category" => 5,
                                      "desc_long" => "Education-related sites and web pages such as schools, colleges, universities, teaching materials, teachers resources; technical and vocational training; online training; education issues and policies;  financial aid; school funding; standards and testing.",
                                      "descr" => "Education",
                                      "mnem" => "edu"),
        Wbrs::Category.new_from_datum("category" => 6,
                                      "desc_long" => "Galleries and exhibitions; artists and art; photography; literature and books; performing arts and theater; musicals; ballet; museums; design; architecture.  Cinema and television are classified as Entertainment.",
                                      "descr" => "Arts",
                                      "mnem" => "art")
    ]
  end
  let(:categories_json) do
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
            "rows_found": 3
        }
    }.to_json
  end
  let(:history_records_json) do
    {
        "data": [
            {
                "action": "insert",
                "category_id": 5,
                "confidence": 1,
                "description": "",
                "event_id": 1,
                "prefix_id": 101,
                "time": "Tue, 20 Mar 2018 14:44:05 GMT",
                "user": "tester333"
            },
            {
                "action": "update",
                "category_id": 6,
                "confidence": 1,
                "description": "",
                "event_id": 2,
                "prefix_id": 101,
                "time": "Tue, 20 Mar 2018 14:56:28 GMT",
                "user": "tester"
            }
        ],
        "meta": {
            "limit": 1000,
            "rows_found": 2
        }
    }.to_json
  end
  let(:categories_error_json) {{'Error' => "No search criteria provided."}.to_json}
  let(:edit_prefix_json) { {"Updated": 101}.to_json }
  let(:edit_prefix_error_json) {{'Error' => "'prefix_id', 'categories', 'user' are required."}.to_json}
  let(:disable_json) { "Done!".to_json }
  let(:disable_error_json) {{'Error' => "'prefix_ids' and 'user' are required."}.to_json}
  let(:history_records_error_json) {{'Error' => "'url', 'categories', 'user' are required."}.to_json}
  let(:categories_response) { double('HTTPI::Response', code: 200, body: categories_json) }
  let(:categories_error) { double('HTTPI::Response', code: 400, body: categories_error_json) }
  let(:history_records_response) { double('HTTPI::Response', code: 200, body: history_records_json) }
  let(:history_records_error) { double('HTTPI::Response', code: 400, body: history_records_error_json) }
  let(:edit_prefix_response) { double('HTTPI::Response', code: 200, body: edit_prefix_json) }
  let(:edit_prefix_error) { double('HTTPI::Response', code: 400, body: edit_prefix_error_json) }
  let(:disable_response) { double('HTTPI::Response', code: 200, body: disable_json) }
  let(:disable_error) { double('HTTPI::Response', code: 400, body: disable_error_json) }
  let(:prefix) do
    Wbrs::Prefix.new_from_attributes(
        "prefix_id": 101,
        "domain": "example.net",
        "is_active": false,
        "path": "",
        "path_hashed": "",
        "port": 0,
        "protocol": "https",
        "subdomain": "",
        "truncated": false
    )
  end
  let(:category) { Wbrs::Category.new_from_datum('category' => 5, 'desc_long' => 'long', 'descr' => 'short', 'mnem' => 'cat5') }



  ### TESTS ####################################################################

  it 'should list its categories' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(categories_response)

    categories = prefix.categories

    expect(categories).to be_a_kind_of(Array)
    expect(categories.count).to eql(2)
    categories = categories.sort_by{ |cat| cat.id }
    expect(categories[0]).to be_a_kind_of(Wbrs::Category)
    expect(categories[0].id).to eql(5)
    expect(categories[1]).to be_a_kind_of(Wbrs::Category)
    expect(categories[1].id).to eql(6)
  end

  it 'should handle errors listing its categories' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(categories_error)

    expect {
      prefix.categories
    }.to raise_error(Wbrs::WbrsError)
  end

  it 'should edit its categories' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(edit_prefix_response)

    edit_prefix_id = prefix.set_categories([category, 6],
                                           user: 'tester',
                                           description: 'Testing /edit route.')

    expect(edit_prefix_id).to eql(101)
  end

  it 'should handle errors editing its categories' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(edit_prefix_error)
    allow(Wbrs::Category).to receive(:all).and_return(all_categories)

    expect {
      prefix.set_categories([],
                            user: 'tester',
                            description: 'Testing /edit route.',
                            prefix_id: 101)
    }.to raise_error(Wbrs::WbrsError)

  end

  it 'should get a history' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(history_records_response)
    allow(Wbrs::Category).to receive(:all).and_return(all_categories)

    history_records = prefix.history_records

    expect(history_records).to be_a_kind_of(Array)
    expect(history_records.count).to eql(2)
    history_record = history_records.first
    expect(history_record.prefix_id).to eql(101)
  end

  it 'should handle errors getting a history' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(history_records_error)

    expect {
      prefix.history_records
    }.to raise_error(Wbrs::WbrsError)
  end

  it 'should disable a list of prefixes' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(disable_response)

    prefix.disable(user: 'tester')

  end

  it 'should handle errors disabling a list of prefixes' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(disable_error)

    expect {
      prefix.disable(user: nil)
    }.to raise_error(Wbrs::WbrsError)

  end

end

describe 'A prefix history record' do
  let(:all_categories) do
    [
        Wbrs::Category.new_from_datum("category" => 5,
                                      "desc_long" => "Education-related sites and web pages such as schools, colleges, universities, teaching materials, teachers resources; technical and vocational training; online training; education issues and policies;  financial aid; school funding; standards and testing.",
                                      "descr" => "Education",
                                      "mnem" => "edu"),
        Wbrs::Category.new_from_datum("category" => 6,
                                      "desc_long" => "Galleries and exhibitions; artists and art; photography; literature and books; performing arts and theater; musicals; ballet; museums; design; architecture.  Cinema and television are classified as Entertainment.",
                                      "descr" => "Arts",
                                      "mnem" => "art")
    ]
  end
  let(:one_rule_link_json) do
    {
        "data": [
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
            "limit": "1",
            "rows_found": 1
        }
    }.to_json
  end
  let(:one_rule_link_response) { double('HTTPI::Response', code: 200, body: one_rule_link_json) }
  let(:history_record) do
    Wbrs::HistoryRecord.new_from_datum(
        'action' => 'insert',
        'category_id' => 2,
        'confidence' => 1,
        'description' => '',
        'event_id' => 1,
        'prefix_id' => 101,
        'time' => 'Tue, 20 Mar 2018 14:44:05 GMT',
        'user' => 'tester333'
    )
  end



  ### TESTS ####################################################################

  it 'should have a prefix' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(one_rule_link_response)
    allow(Wbrs::Category).to receive(:all).and_return(all_categories)

    prefix = history_record.prefix

    expect(prefix).to be_a_kind_of(Wbrs::Prefix)
  end
end
