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

  it 'should add a whitelist entry'
  it 'should handle errors adding a whitelist entry'

end

describe 'A whitelist' do

  it 'should delete a whitelist entry'
  it 'should handle errors deleting a whitelist entry'

end
