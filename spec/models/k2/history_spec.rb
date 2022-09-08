describe K2::History do
  let(:domain) { 'cisco.com' }
  let(:time_ingeger) { 1662639710475 }
  let!(:response_body) do
    {
      "mapVersion" => 6,
      "queryStartTime" => 1662639710475,
      "queryEndTime" => 1662639710475,
      "queryResults" => [{
        "element" => "cisco.com",
        "timelines" => [{
          "time" => time_ingeger,
          "score" => 9.3,
          "aups" => [{
            "cat" => "comp",
            "version" => "V2"
          }, {
            "cat" => "comp",
            "version" => "V3",
            "order" => "1"
          }],
          "threatCats" => [],
          "ruleHits" => ["suwl", "white_medium_url", "white_heavy_url", "tuse", "vsvd"]
        }]
      }]
    }
  end
 
  describe '.search' do
    let(:response) { HTTPI::Response.new(rand(200..299), {}, '') }
    context 'when search is failed' do
      before do
        allow(HTTPI).to receive(:post).and_raise(:boom)
      end

      it 'calls handle_error_response method' do
        expect(described_class).to receive(:handle_error_response).with(nil)
        described_class.search(domain)
      end
    end

    context 'when search is successfull' do
      let(:response) { HTTPI::Response.new(rand(200..2999), {}, response_body.to_json) }
      before do
        allow(HTTPI).to receive(:post).and_return(response)
      end

      it 'calls handle_error_response method with succsesfull response' do
        expect(described_class).to receive(:handle_error_response).with(response)
        described_class.search(domain)
      end
    end

    context '.parsed_data_for' do
      before do
        allow_any_instance_of(HTTPI::Response).to receive(:body).and_return(response_body.to_json)
        allow_any_instance_of(HTTPI::Response).to receive(:code).and_return(rand(200..299))
        allow_any_instance_of(described_class::Response).to receive(:error).and_return(false)
      end

      it 'group querryResults by element' do
        result = described_class.parsed_data_for(domain)
        expect(result.keys).to eq(['cisco.com'])
      end

      it 'transforms time to readable DATE_FORMAT' do
        result = described_class.parsed_data_for(domain)
        expect(result['cisco.com'].first['time']).to eq(Time.at(time_ingeger/1000).strftime(described_class::DATE_FORMAT))
      end
    end
  end
end
