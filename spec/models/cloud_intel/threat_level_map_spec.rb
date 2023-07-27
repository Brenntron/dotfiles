require 'rails_helper'

RSpec.describe CloudIntel::ThreatLevelMap do
  describe '.get_threat_level_mnemonic' do
    context 'when GRPC::Unavailable is raised in load_map' do
      before do
        Rails.cache.clear
        allow(Beaker::Sdr).to receive(:query_threat_level_map).and_raise(GRPC::Unavailable)
      end

      it 'returns "unknown"' do
        expect(CloudIntel::ThreatLevelMap.get_threat_level_mnemonic(1)).to eq('unknown')
      end
    end

    context 'when Rails.cache threat_level_map is present' do
      let(:neutral_level_map) do
        {
          "threat_level_id" => 1,
          "threat_level_mnemonic" => 'untrusted',
          "score_lower_bound_x10" => 900,
          "score_upper_bound_x10" => 1000,
          "desc_short" => [
            {
              "language" => "en-us",
              "text" => "Untrusted"
            }
          ],
          "desc_long" => [
            {
              "language" => "en-us",
              "text" => "Displaying behavior that is exceptionally bad, malicious, or undesirable."
            }
          ],
          "vers_avail" => {
            "starting" => 1,
            "ending" => 0
          },
          "is_avail" => true,
          "sort_index" => 5
        }
      end

      let(:threat_level_map) { { 'threat_levels' => [neutral_level_map] } }

      before do
        Rails.cache.write('threat_level_map', threat_level_map.to_json)
      end

      it 'returns untrused' do
        expect(CloudIntel::ThreatLevelMap.get_threat_level_mnemonic(1)).to eq('untrusted')
      end
    end

    context 'when Rails.cache threat_level_map is not present' do
      let(:level) { 'questionable'}
      let(:thrat_levels) do
        [
          Talos::ThreatLevel.new(
            threat_level_id: 2,
            threat_level_mnemonic: level,
            score_lower_bound_x10: 800,
            score_upper_bound_x10: 890,
            desc_short: [Talos::LocalizedString.new(language: "en-us", text: "Questionable")],
            desc_long: [Talos::LocalizedString.new(language: "en-us", text: "Displaying behavior that may indicate risk, or could be undesirable.")],
            vers_avail: Talos::VersionRange.new(starting: 1, ending: 0),
            is_avail: true,
            sort_index: 6
          )
        ]
      end

      let(:threat_level_map) do
        Talos::ThreatLevelMap.new(
          threat_levels: thrat_levels,
          version: 1,
          map_is_complete: true)
      end

      before do
        Rails.cache.clear
        allow(Beaker::Sdr).to receive(:query_threat_level_map).and_return(threat_level_map)
      end

      it 'returns questionable from Rails cache' do
        result = JSON.parse(CloudIntel::ThreatLevelMap.cache_map)
        expect(result['threat_levels'].first['threat_level_mnemonic']).to eq(level)
        result2 = JSON.parse(Rails.cache.read('threat_level_map'))['threat_levels']
        expect(result2.first['threat_level_mnemonic']).to eq(level)
      end

      it 'returns questionable' do
        Rails.cache.clear
        expect(described_class.get_threat_level_mnemonic('2')).to eq(level)
      end
    end
  end
end
