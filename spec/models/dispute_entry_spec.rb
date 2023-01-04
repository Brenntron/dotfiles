describe DisputeEntry do
  let!(:customer) { FactoryBot.create(:customer) }
  let!(:dispute) { FactoryBot.create(:dispute, customer: customer) }
  let!(:dispute_entry) { FactoryBot.create(:dispute_entry, dispute: dispute) }
  let(:ip_address) { '192.168.1.1' }
  let(:k2_timeline) do
    [{
          "time" => 1662639710475,
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
  end

  let(:k2_response) do
    {
      "mapVersion" => 6,
      "queryStartTime" => 1662639710475,
      "queryEndTime" => 1662639710475,
      "queryResults" => [{
        "element" => dispute_entry.uri,
        "timelines" => k2_timeline
      }]
    }
  end
  let(:k2_stub) { HTTPI::Response.new(rand(200..2999), {}, k2_response) }
  
  before do
    #stub all the external calls for Preloader::Base
    allow(RepApi::Blacklist).to receive(:where).and_return(nil)
    allow(Virustotal::GetVirustotal).to receive(:by_domain).and_return(nil)
    allow(Wbrs::ManualWlbl).to receive(:where).and_return(nil)
    allow_any_instance_of(AutoResolve).to receive(:call_umbrella).and_return(nil)
    allow(Sbrs::ManualSbrs).to receive(:get_sbrs_data).and_return({"sbrs"=> {"score"=> 0, "categories"=> []}})
    allow(K2::History).to receive(:url_lookup).and_return(k2_stub)
    allow(K2::History).to receive(:ip_lookup).and_return(k2_stub)
end

  describe '#xbrs_timeline' do
    context 'when entry_type is URI/DOMAIN' do 
      it 'calls K2::History.url_lookup' do
        expect(K2::History).to receive(:url_lookup).with(dispute_entry.uri)
        dispute_entry.xbrs_timeline
      end
    end

    context 'when entry_type is IP' do
      before do
        dispute_entry.update(entry_type: 'IP', ip_address: ip_address)
      end

      it 'calls K2::History.url_lookup' do
        expect(K2::History).to receive(:ip_lookup).with(dispute_entry.ip_address)
        dispute_entry.xbrs_timeline
      end
    end

    context 'when entry has preloaded data' do
      let!(:dispute_entry_preload) { FactoryBot.create(:dispute_entry_preload, dispute_entry: dispute_entry, xbrs_history: {k2: k2_timeline}.to_json) }
      
      it 'gets data from dispute_entry_preload and does not call K2 api' do
        expect(K2::History).not_to receive(:url_lookup)
        expect(K2::History).not_to receive(:ip_lookup)

        result = dispute_entry.xbrs_timeline
        expect(result).to eq(k2_timeline)
      end
    end

    context 'when entry does not have preloaded data' do
      it 'created dispute_entry_preload with xbrs_history' do
        expect(dispute_entry.dispute_entry_preload).to be_nil
        dispute_entry.xbrs_timeline
        expect(dispute_entry.dispute_entry_preload.xbrs_history).to eq({k2: k2_timeline}.to_json)
      end
    end
  end
end
