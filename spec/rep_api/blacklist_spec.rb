describe RepApi::Blacklist do
  let(:classifications_json) do
    %w(attackers bogon bots cnc dga exploitkit malware open_proxy open_relay
       phishing response spam suspicious tor_exit_node).to_json
  end
  let(:get_blacklist_json) do
    {
        "1.1.1.1" => "NOT_FOUND",
        "unknownhost.com" => "NOT_FOUND",
        "badbadsite.com" => {
            "public" => "false",
            "classifications" => [
                "malware",
                "bogon" ],
            "class_id" => 1,
            "expiration" => "2016‐05‐31 15:07:02.321397‐04",
            "hostname" => "badbadsite.com",
            "_rev" => 18,
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
  let(:classifications_response) { double('HTTPI::Response', code: 200, body: classifications_json) }
  let(:get_blacklist_response) { double('HTTPI::Response', code: 200, body: get_blacklist_json) }
  let(:get_blacklist_not_found) { double('HTTPI::Response', code: 404, body: get_blacklist_not_found_json) }
  let(:get_blacklist_error) { double('HTTPI::Response', code: 400, body: get_blacklist_error_json) }



  ### TESTS ####################################################################

  it 'should list the classifications' do
    expect(RepApi::Base).to receive(:call_request).and_return(classifications_response)

    classifications = RepApi::Blacklist.classifications

    expect(classifications).to be_a_kind_of(Array)
    expect(classifications.count).to eql(14)
    expect(classifications[0]).to be_a_kind_of(String)
  end

  it 'should get blacklists from a query' do
    expect(RepApi::Base).to receive(:call_request).and_return(get_blacklist_response)

    blacklists = RepApi::Blacklist.where(entries: ['A Blacklist Entry', 'Another Entry'])

    expect(blacklists).to be_a_kind_of(Array)
    expect(blacklists.count).to eql(1)
    expect(blacklists[0]).to be_a_kind_of(RepApi::Blacklist)
  end

  it 'should handle not found from a query' do
    expect(RepApi::Base).to receive(:call_request).and_return(get_blacklist_not_found)

    blacklists = nil
    expect {
      blacklists = RepApi::Blacklist.where(entries: ['A Blacklist Entry', 'Another Entry'])
    }.to_not raise_error(Exception)


    expect(blacklists).to be_a_kind_of(Array)
    expect(blacklists.count).to eql(0)
  end
  
  it 'should handle errors getting blacklists from a query' do
    expect(RepApi::Base).to receive(:call_request).and_return(get_blacklist_error)

    expect {
      RepApi::Blacklist.where(entries: ['A Blacklist Entry', 'Another Entry'])
    }.to raise_error(RepApi::RepApiError)
  end

end

describe 'A blacklist' do
  let(:blacklist_entry) { '75.125.228.68' }
  let(:blacklist) do
    RepApi::Blacklist.new(entry: blacklist_entry,
                          author: 'awalker',
                          public: false,
                          excluded: false)
  end
  let(:loaded_blacklist) do
    RepApi::Blacklist.load_from_attributes(entry: blacklist_entry,
                                           author: 'awalker',
                                           public: false,
                                           excluded: false)
  end
  let(:add_blacklist_json) { [{"MSG" => "Entry created", "entry" => blacklist_entry, "expiration" => "2013‐05‐08T10:05:02"}].to_json }
  let(:add_blacklist_json) { [{"MSG" => "Entry created", "entry" => blacklist_entry, "expiration" => "2013‐05‐08T10:05:02"}].to_json }
  let(:add_blacklist_error_json) { {"MSG" => "Invalid IP or CIDR address: 256.0.0.1/900"}.to_json }
  let(:update_blacklist_json) { [{"MSG" => "Entry updated", "entry" => blacklist_entry, "expiration" => "2013‐05‐08T10:05:02"}].to_json }
  let(:update_blacklist_error_json) { {"MSG" => "Invalid IP or CIDR address: 256.0.0.1/900"}.to_json }
  let(:exlude_blacklist_error_json) { {"MSG" => "Entry is already excluded"}.to_json }
  let(:renew_blacklist_error_json) { {"MSG" => "Entry is not excluded"}.to_json }
  let(:expire_blacklist_error_json) { {"MSG" => "No matching entries found"}.to_json }
  let(:delete_blacklist_json) { {"MSG" => "Entry deleted"}.to_json }
  let(:delete_blacklist_error_json) { {"MSG" => "Entry not exists in blacklist"}.to_json }
  let(:expire_blacklist_json) { {"MSG" => "Entry has been set to expired."}.to_json }
  let(:add_blacklist_response) { double('HTTPI::Response', code: 200, body: add_blacklist_json) }
  let(:add_blacklist_error) { double('HTTPI::Response', code: 400, body: add_blacklist_error_json) }
  let(:update_blacklist_response) { double('HTTPI::Response', code: 200, body: update_blacklist_json) }
  let(:update_blacklist_error) { double('HTTPI::Response', code: 400, body: update_blacklist_error_json) }
  let(:exclude_blacklist_response) { double('HTTPI::Response', code: 200, body: {}.to_json) }
  let(:exclude_blacklist_error) { double('HTTPI::Response', code: 400, body: exlude_blacklist_error_json) }
  let(:renew_blacklist_response) { double('HTTPI::Response', code: 200, body: {}.to_json) }
  let(:renew_blacklist_error) { double('HTTPI::Response', code: 400, body: renew_blacklist_error_json) }
  let(:expire_blacklist_response) { double('HTTPI::Response', code: 200, body: expire_blacklist_json) }
  let(:expire_blacklist_error) { double('HTTPI::Response', code: 400, body: expire_blacklist_error_json) }
  let(:delete_blacklist_response) { double('HTTPI::Response', code: 200, body: delete_blacklist_json) }
  let(:delete_blacklist_error) { double('HTTPI::Response', code: 400, body: delete_blacklist_error_json) }



  ### TESTS ####################################################################

  it 'should add a blacklist entry' do
    expect(RepApi::Base).to receive(:call_request).and_return(add_blacklist_response)

    ret = nil
    expect {
      @blacklist = RepApi::Blacklist.new(entry: [blacklist_entry], classifications: [ 'bots', 'spam' ])
      ret = @blacklist.save!(author: 'dtrump', comment: 'blah')
    }.to_not raise_error(Exception)

    expect(@blacklist.new_record?).to be_falsey
    expect(ret).to be_a_kind_of(Array)
    expect(ret.count).to eq(1)
    blacklist = ret.first
    expect(blacklist).to be_a_kind_of(RepApi::Blacklist)
    expect(blacklist.entry).to eq(blacklist_entry)
  end
  
  it 'should handle errors adding a blacklist entry' do
    expect(RepApi::Base).to receive(:call_request).and_return(add_blacklist_error)

    expect {
      @blacklist = RepApi::Blacklist.new(entry: [blacklist_entry], classifications: [ 'bots', 'spam' ])
      ret = @blacklist.save!(author: 'dtrump', comment: 'blah')
    }.to raise_error(RepApi::RepApiError)
  end

  it 'should update a blacklist entry' do
    expect(RepApi::Base).to receive(:call_request).and_return(update_blacklist_response)

    ret = nil
    expect {
      @blacklist = RepApi::Blacklist.new(entry: [blacklist_entry], classifications: [ 'bots', 'spam' ])
      ret = @blacklist.save!(author: 'dtrump', comment: 'blah')
    }.to_not raise_error(Exception)

    expect(@blacklist.new_record?).to be_falsey
    expect(ret).to be_a_kind_of(Array)
    expect(ret.count).to eq(1)
    blacklist = ret.first
    expect(blacklist).to be_a_kind_of(RepApi::Blacklist)
    expect(blacklist.entry).to eq(blacklist_entry)
  end

  it 'should handle errors updating a blacklist entry' do
    expect(RepApi::Base).to receive(:call_request).and_return(update_blacklist_error)

    expect {
      @blacklist = RepApi::Blacklist.new(entry: [blacklist_entry], classifications: [ 'bots', 'spam' ])
      ret = @blacklist.save!(author: 'dtrump', comment: 'blah')
    }.to raise_error(RepApi::RepApiError)
  end

  it 'should exclude a blacklist entry' do
    expect(RepApi::Base).to receive(:call_request).and_return(exclude_blacklist_response)

    expect {
      blacklist.exclude
    }.to_not raise_error(Exception)
  end

  it 'should handle errors excluding a blacklist entry' do
    expect(RepApi::Base).to receive(:call_request).and_return(exclude_blacklist_error)

    expect {
      blacklist.exclude
    }.to raise_error(RepApi::RepApiError)
  end

  it 'should renew a blacklist entry' do
    expect(RepApi::Base).to receive(:call_request).and_return(renew_blacklist_response)

    expect {
      blacklist.renew
    }.to_not raise_error(Exception)
  end

  it 'should handle errors renewing a blacklist entry' do
    expect(RepApi::Base).to receive(:call_request).and_return(renew_blacklist_error)

    expect {
      blacklist.renew
    }.to raise_error(RepApi::RepApiError)
  end

  it 'should expire a blacklist entry' do
    expect(RepApi::Base).to receive(:call_request).and_return(expire_blacklist_response)

    expect {
      blacklist.expire
    }.to_not raise_error(Exception)
  end

  it 'should handle errors expiring a blacklist entry' do
    expect(RepApi::Base).to receive(:call_request).and_return(expire_blacklist_error)

    expect {
      blacklist.expire
    }.to raise_error(RepApi::RepApiError)
  end

  it 'should delete a blacklist entry' do
    expect(RepApi::Base).to receive(:call_request).and_return(delete_blacklist_response)

    expect {
      blacklist.delete!
    }.to_not raise_error(Exception)

  end
  
  it 'should handle errors deleting a blacklist entry' do
    expect(RepApi::Base).to receive(:call_request).and_return(delete_blacklist_error)

    expect {
      blacklist.delete!
    }.to raise_error(RepApi::RepApiError)

  end

end
