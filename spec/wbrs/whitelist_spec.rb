describe Wbrs::Whitelist do
  let(:get_whitelist_json) do
    {
        "NOT_FOUND" => [
            "goodsite.com"
        ],
        "75.125.228.68" => {
            "source" => "awalker",
            "comment" => "keegy.com",
            "range" => "75.125.0.0/16",
            "ident" => "alexa001"
        },
        "77.101.99.68" => {
            "source" => "awalker",
            "comment" => "keegy.com",
            "range" => "75.125.0.0/16",
            "ident" => "alexa001"
        }
    }.to_json
  end
  let(:get_whitelist_not_found_json) do
    {"MSG":"No matching entries found"}.to_json
  end
  let(:get_whitelist_error_json) do
    {"MSG":"Bad Request"}.to_json
  end
  let(:get_whitelist_response) { double('HTTPI::Response', code: 200, body: get_whitelist_json) }
  let(:get_whitelist_not_found) { double('HTTPI::Response', code: 404, body: get_whitelist_not_found_json) }
  let(:get_whitelist_error) { double('HTTPI::Response', code: 400, body: get_whitelist_error_json) }



  ### TESTS ####################################################################

  it 'should get whitelists from a query' do
    expect(Wbrs::Base).to receive(:call_request).and_return(get_whitelist_response)

    whitelists = Wbrs::Whitelist.where(entry: ['A Whitelist Entry', 'Another Entry'])

    expect(whitelists).to be_a_kind_of(Array)
    expect(whitelists.count).to eql(2)
    expect(whitelists[0]).to be_a_kind_of(Wbrs::Whitelist)
    expect(whitelists[1]).to be_a_kind_of(Wbrs::Whitelist)
  end

  it 'should handle not found from a query' do
    expect(Wbrs::Base).to receive(:call_request).and_return(get_whitelist_not_found)

    whitelists = nil
    expect {
      whitelists = Wbrs::Whitelist.where(entry: ['A Whitelist Entry', 'Another Entry'])
    }.to_not raise_error(Exception)


    expect(whitelists).to be_a_kind_of(Array)
    expect(whitelists.count).to eql(0)
  end

  it 'should handle errors getting whitelists from a query' do
    expect(Wbrs::Base).to receive(:call_request).and_return(get_whitelist_error)

    expect {
      Wbrs::Whitelist.where(entry: ['A Whitelist Entry', 'Another Entry'])
    }.to raise_error(Wbrs::WbrsError)
  end

end

describe 'A whitelist' do
  let(:whitelist) do
    Wbrs::Whitelist.new(entry: '75.125.228.68',
                        source: 'awalker',
                        range: '75.125.0.0/16',
                        ident: 'alexa001',
                        comment: 'keegy.com')
  end
  let(:add_whitelist_json) { {"MSG": "Entry created"}.to_json }
  let(:add_whitelist_error_json) { {"MSG": "Invalid IP or CIDR address: 256.0.0.1/900"}.to_json }
  let(:delete_whitelist_json) { {"MSG": "Entry deleted"}.to_json }
  let(:delete_whitelist_error_json) { {"MSG": "Entry not exists in whitelist"}.to_json }
  let(:add_whitelist_response) { double('HTTPI::Response', code: 200, body: add_whitelist_json) }
  let(:add_whitelist_error) { double('HTTPI::Response', code: 400, body: add_whitelist_error_json) }
  let(:delete_whitelist_response) { double('HTTPI::Response', code: 200, body: delete_whitelist_json) }
  let(:delete_whitelist_error) { double('HTTPI::Response', code: 400, body: delete_whitelist_error_json) }



  ### TESTS ####################################################################

  it 'should add a whitelist entry' do
    expect(Wbrs::Base).to receive(:call_request).and_return(add_whitelist_response)

    ret = nil
    expect {
      ret = whitelist.save!
    }.to_not raise_error(Exception)

    expect(ret).to eql(true)
    expect(whitelist.new_record?).to be_falsey
  end

  it 'should handle errors adding a whitelist entry' do
    expect(Wbrs::Base).to receive(:call_request).and_return(add_whitelist_error)

    expect {
      whitelist.save!
    }.to raise_error(Wbrs::WbrsError)
  end

  it 'should delete a whitelist entry' do
    expect(Wbrs::Base).to receive(:call_request).and_return(delete_whitelist_response)

    expect {
      whitelist.delete(comment: 'Just for the thrill.')
    }.to_not raise_error(Exception)

  end

  it 'should handle errors deleting a whitelist entry' do
    expect(Wbrs::Base).to receive(:call_request).and_return(delete_whitelist_error)

    expect {
      whitelist.delete(comment: 'Just for the thrill.')
    }.to raise_error(Wbrs::WbrsError)

  end

end
