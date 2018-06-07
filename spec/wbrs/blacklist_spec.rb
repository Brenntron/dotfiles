describe Wbrs::Blacklist do
  let(:get_blacklist_json) do
    {
        "NOT_FOUND" => [
            "1.1.1.1",
            "unknownhost.com"
        ],
        "badbadsite.com" => {
            "public" => "false",
            "classifications" => [
                "malware",
                "bogon" ],
            "class_id" => 1,
            "expiration" => "2016‐05‐31 15:07:02.321397‐04",
            "hostname" => "badbadsite.com",
            "rev" => 18,
            "stale" => "false",
            "last_seen" => "2016‐05‐02 14:25:44.271465‐04",
            "primary_source" => "VRT",
            "metadata" => {
                "VRT" => {
                    "comment" => "some comment again",
                    "added_by" => "JamesSu"
                }
            },
            "excluded" => "false",
            "seen_by" => {
                "VRT" => 1 },
            "first_seen" => "2016‐05‐02 14:25:44.271465‐04",
            "disposition" => 3,
            "manual_classifications" => [
                "malware",
                "bogon" ]
        }
    }.to_json
  end
  let(:get_blacklist_not_found_json) do
    {"MSG":"No matching entries found"}.to_json
  end
  let(:get_blacklist_error_json) do
    {"MSG":"Bad Request"}.to_json
  end
  let(:get_blacklist_response) { double('HTTPI::Response', code: 200, body: get_blacklist_json) }
  let(:get_blacklist_not_found) { double('HTTPI::Response', code: 404, body: get_blacklist_not_found_json) }
  let(:get_blacklist_error) { double('HTTPI::Response', code: 400, body: get_blacklist_error_json) }



  ### TESTS ####################################################################

  it 'should list the classifications'

  it 'should get blacklists from a query' do
    expect(Wbrs::Base).to receive(:call_request).and_return(get_blacklist_response)

    blacklists = Wbrs::Blacklist.where(entry: ['A Blacklist Entry', 'Another Entry'])

    expect(blacklists).to be_a_kind_of(Array)
    expect(blacklists.count).to eql(1)
    expect(blacklists[0]).to be_a_kind_of(Wbrs::Blacklist)
  end

  it 'should handle not found from a query' do
    expect(Wbrs::Base).to receive(:call_request).and_return(get_blacklist_not_found)

    blacklists = nil
    expect {
      blacklists = Wbrs::Blacklist.where(entry: ['A Blacklist Entry', 'Another Entry'])
    }.to_not raise_error(Exception)


    expect(blacklists).to be_a_kind_of(Array)
    expect(blacklists.count).to eql(0)
  end
  
  it 'should handle errors getting blacklists from a query' do
    expect(Wbrs::Base).to receive(:call_request).and_return(get_blacklist_error)

    expect {
      Wbrs::Blacklist.where(entry: ['A Blacklist Entry', 'Another Entry'])
    }.to raise_error(Wbrs::WbrsError)
  end

end

describe 'A blacklist' do
  let(:blacklist) do
    Wbrs::Blacklist.new(entry: '75.125.228.68',
                        author: 'awalker',
                        public: false,
                        excluded: false,
                        comment: 'keegy.com')
  end
  let(:add_blacklist_json) { {"MSG": "Entry created"}.to_json }
  let(:add_blacklist_error_json) { {"MSG": "Invalid IP or CIDR address: 256.0.0.1/900"}.to_json }
  let(:delete_blacklist_json) { {"MSG": "Entry deleted"}.to_json }
  let(:delete_blacklist_error_json) { {"MSG": "Entry not exists in blacklist"}.to_json }
  let(:add_blacklist_response) { double('HTTPI::Response', code: 200, body: add_blacklist_json) }
  let(:add_blacklist_error) { double('HTTPI::Response', code: 400, body: add_blacklist_error_json) }
  let(:delete_blacklist_response) { double('HTTPI::Response', code: 200, body: delete_blacklist_json) }
  let(:delete_blacklist_error) { double('HTTPI::Response', code: 400, body: delete_blacklist_error_json) }



  ### TESTS ####################################################################

  it 'should add a blacklist entry' do
    expect(Wbrs::Base).to receive(:call_request).and_return(add_blacklist_response)

    ret = nil
    expect {
      ret = blacklist.save!
    }.to_not raise_error(Exception)

    expect(ret).to eql(true)
    expect(blacklist.new_record?).to be_falsey
  end
  
  it 'should handle errors adding a blacklist entry' do
    expect(Wbrs::Base).to receive(:call_request).and_return(add_blacklist_error)

    expect {
      blacklist.save!
    }.to raise_error(Wbrs::WbrsError)
  end

  it 'should update a blacklist entry'
  it 'should handle errors updating a blacklist entry'

  it 'should exclude a blacklist entry'
  it 'should handle errors excluding a blacklist entry'

  it 'should renew a blacklist entry'
  it 'should handle errors renewing a blacklist entry'

  it 'should expire a blacklist entry'
  it 'should handle errors expiring a blacklist entry'

  it 'should delete a blacklist entry' do
    expect(Wbrs::Base).to receive(:call_request).and_return(delete_blacklist_response)

    expect {
      blacklist.delete(comment: 'Just for the thrill.')
    }.to_not raise_error(Exception)

  end
  
  it 'should handle errors deleting a blacklist entry' do
    expect(Wbrs::Base).to receive(:call_request).and_return(delete_blacklist_error)

    expect {
      blacklist.delete(comment: 'Just for the thrill.')
    }.to raise_error(Wbrs::WbrsError)

  end

end
