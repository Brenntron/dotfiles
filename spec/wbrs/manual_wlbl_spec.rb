describe Wbrs::ManualWlbl do
  let(:wlbl_types_json) do
    {
        'data' => %w(WL-weak WL-med WL-heavy BL-weak BL-med BL-heavy)
    }.to_json
  end
  let(:find_wlbl_json) do
    {
        "ctime": "Fri, 04 May 2018 19:21:06 GMT",
        "id": 101,
        "list_type": "WL-weak",
        "notes" => [
            {
                "ctime": "Tue, 22 May 2018 13:37:43 GMT",
                "note": "Hello",
                "user": "aivaniuk"
            },
            {
                "ctime": "Thu, 24 May 2018 10:55:17 GMT",
                "note": "test1",
                "user": "aivaniuk"
            },
            {
                "ctime": "Thu, 24 May 2018 10:55:18 GMT",
                "note": "test2",
                "user": "tester2"
            }
        ],
        "threat_cats": [5, 6],
        "url": "url6.com",
        "username": "aivaniuk",
        "state": "active"
    }.to_json
  end
  let(:where_wlbl_json) do
    {
        "data": [
            {
                "ctime": "Fri, 04 May 2018 19:21:06 GMT",
                "id": 1,
                "list_type": "BL-weak",
                "mtime": "Fri, 04 May 2018 19:21:06 GMT",
                "threat_cats": [5, 6],
                "url": "url1.com",
                "username": "aivaniuk",
                "state": "active"
            },
            {
                "ctime": "Mon, 07 May 2018 12:10:59 GMT",
                "id": 2,
                "list_type": "WL-weak",
                "mtime": "Mon, 07 May 2018 12:10:59 GMT",
                "threat_cats": [],
                "url": "url4.com",
                "username": "aivaniuk",
                "state": "deleted"
            }
        ],
        "meta": {
            "limit": 5,
            "rows_found": 2
        }
    }.to_json
  end
  let(:add_wlbl_json) do
    {
        "Warnings": [
            "URLs ['url'] are invalid.",
            "URLs ['url1.com'] already exist in 'BL-weak' list."
        ],
        "ids": [209053,209054]


    }.to_json
  end
  let(:wlbl_params) do
    {
        "urls": %w(www.google.com www.cisco.com),
        "usr": 'ancheng3'
    }
  end
  let(:error_wlbl_params) do
    {
        "usr": 'ancheng3'
    }
  end

  before do
    FactoryBot.create(:customer)
    FactoryBot.create(:dispute)
    FactoryBot.create(:dispute_entry)
    FactoryBot.create(:dispute_entry)

  end

  let(:dispute_entry) { [DisputeEntry.find(1),DisputeEntry.find(2)]}

  let(:find_wlbl_error_json) {'{"Error": "WL/BL entry with ID \'101\' not found."}'}
  let(:where_wlbl_error_json) {'{"Error": "No search criteria provided."}'}
  let(:add_wlbl_error_json) {'{"Error": "Invalid data format."}'}
  let(:wlbl_types_response) { double('HTTPI::Response', code: 200, body: wlbl_types_json) }
  let(:find_wlbl_response) { double('HTTPI::Response', code: 200, body: find_wlbl_json) }
  let(:find_wlbl_error) { double('HTTPI::Response', code: 400, body: find_wlbl_error_json) }
  let(:where_wlbl_response) { double('HTTPI::Response', code: 200, body: where_wlbl_json) }
  let(:where_wlbl_error) { double('HTTPI::Response', code: 400, body: where_wlbl_error_json) }
  let(:add_wlbl_response) { double('HTTPI::Response', code: 200, body: add_wlbl_json) }
  let(:add_wlbl_error) { double('HTTPI::Response', code: 400, body: add_wlbl_error_json) }



  ### TESTS ####################################################################

  it 'should get all the types' do
    expect(Wbrs::Base).to receive(:call_request).and_return(wlbl_types_response)

    wlbl_types = Wbrs::ManualWlbl.types

    expect(wlbl_types).to be_a_kind_of(Array)
    wlbl_types = wlbl_types.sort
    expect(wlbl_types.count).to eql(6)
    expect(wlbl_types[0]).to eq('BL-heavy')
    expect(wlbl_types[1]).to eq('BL-med')
    expect(wlbl_types[2]).to eq('BL-weak')
    expect(wlbl_types[3]).to eq('WL-heavy')
    expect(wlbl_types[4]).to eq('WL-med')
    expect(wlbl_types[5]).to eq('WL-weak')
  end

  it 'should find a WL/BL by id' do
    expect(Wbrs::Base).to receive(:call_request).and_return(find_wlbl_response)

    manual_wlbl = Wbrs::ManualWlbl.find(101)

    expect(manual_wlbl).to be_a_kind_of(Wbrs::ManualWlbl)
    expect(manual_wlbl.id).to eql(101)
  end

  it 'should handle errors finding a WL/BL by id' do
    expect(Wbrs::Base).to receive(:call_request).and_return(find_wlbl_error)

    expect {
      Wbrs::ManualWlbl.find(101)
    }.to raise_error(Wbrs::WbrsError)
  end

  it 'should get all the manual WL/BL entries' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(where_wlbl_response)

    manual_wlbls = Wbrs::ManualWlbl.where("usr" => "aivaniuk")

    expect(manual_wlbls).to be_a_kind_of(Array)
    manual_wlbls = manual_wlbls.sort_by{ |wlbl| wlbl.id }
    expect(manual_wlbls.count).to eql(2)
    expect(manual_wlbls[0].id).to eql(1)
    expect(manual_wlbls[1].id).to eql(2)
  end

  it 'should handle errors getting all the manual WL/BL entries' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(where_wlbl_error)

    expect {
      Wbrs::ManualWlbl.where
    }.to raise_error(Wbrs::WbrsError)
  end

  it 'should add a WL/BL on the backend' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(add_wlbl_response)

    response = Wbrs::ManualWlbl.add_from_params(dispute_entry, wlbl_params)

    warnings = JSON.parse(response)['Warnings']
    
    expect(warnings).to be_a_kind_of(Array)
    expect(warnings.count).to eql(2)
    expect(warnings[0]).to be_a_kind_of(String)
    expect(warnings[1]).to be_a_kind_of(String)
    expect(DisputeEntry.find(1).webrep_wlbl_key).to eq(209053)
    expect(DisputeEntry.find(2).webrep_wlbl_key).to eq(209054)
  end

  it 'should handle errors adding a WL/BL on the backend' do
    expect(Wbrs::Base).to receive(:make_post_request).and_return(add_wlbl_error)

    expect {
      Wbrs::ManualWlbl.add_from_params(dispute_entry, error_wlbl_params)
    }.to raise_error(Wbrs::WbrsError)
  end

end
