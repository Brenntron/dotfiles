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
  let(:response) { HTTPI::Response.new(rand(200..299), {}, '') }
 
  describe '.url_lookup' do
    context 'when search is failed' do
      before do
        allow(HTTPI).to receive(:get).and_raise(:boom)
      end

      it 'calls handle_error_response method' do
        expect(described_class).to receive(:handle_error_response).with(nil)
        described_class.url_lookup(domain)
      end
    end

    context 'when search is successfull' do
      let(:response) { HTTPI::Response.new(rand(200..2999), {}, response_body.to_json) }
      before do
        allow(HTTPI).to receive(:get).and_return(response)
      end

      it 'calls handle_error_response method with succsesfull response' do
        expect(described_class).to receive(:handle_error_response).with(response)
        k2_data = described_class.url_lookup(domain)
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
      
      describe 'is_important flag' do
        context 'when element is important' do
          before do
            allow(ComplaintEntry).to receive(:self_importance).and_return(true)
          end

          it 'sets is_important flag to true' do
            result = described_class.parsed_data_for(domain)
            expect(result['cisco.com'].sample['is_important']).to eq(true)
          end
        end

        context 'when element is not important' do
          before do
            allow(ComplaintEntry).to receive(:self_importance).and_return(false)
          end

          it 'returns true' do
            allow(ComplaintEntry).to receive(:self_importance).and_return(false)

            result = described_class.parsed_data_for(domain)
            expect(result['cisco.com'].sample['is_important']).to eq(false)
          end
        end

        context 'when XBRS retuns nil' do
          before do
            allow(ComplaintEntry).to receive(:self_importance).and_return(nil)
          end

          it 'returns false' do
            result = described_class.parsed_data_for(domain)
            expect(result['cisco.com'].sample['is_important']).to eq(false)
          end
        end
      end
    end
  end

  describe '.ip_lookup' do
    let(:ip_address) { '192.168.1.1' }
    context 'when search is failed' do
      before do
        allow(HTTPI).to receive(:get).and_raise(:boom)
      end

      it 'calls handle_error_response method' do
        expect(described_class).to receive(:handle_error_response).with(nil)
        described_class.ip_lookup(ip_address)
      end
    end

    context 'when search is successfull' do
      let(:response) { HTTPI::Response.new(rand(200..2999), {}, response_body) }
      before do
        allow(HTTPI).to receive(:get).and_return(response)
      end

      it 'calls handle_error_response method with succsesfull response' do
        expect(described_class).to receive(:handle_error_response).with(response)
        described_class.ip_lookup(ip_address)
      end
    end
  end
end
