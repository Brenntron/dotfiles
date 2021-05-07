describe Clusters::Ngfw::DataFetcher do
  subject { described_class.new(regex) }

  before do
    FactoryBot.create(:ngfw_cluster, domain: 'example.com', traffic_hits: 123)
    FactoryBot.create(:ngfw_cluster, domain: '127.0.0.1', traffic_hits: 124)
  end

  describe('.fetch') do
    context 'when regex is blank' do
      let(:regex) { nil }
      let(:expected_response) do
        [
          {
            :cluster_id=>"",
            :cluster_size=>nil,
            :domain=>"127.0.0.1",
            :global_volume=>124,
            :is_pending=>false,
            :categories=>[],
            :platform=>"NGFW"
          },
          {
            :cluster_id=>"",
            :cluster_size=>nil,
            :domain=>"example.com",
            :global_volume=>123,
            :is_pending=>false,
            :categories=>[],
            :platform=>"NGFW"
          }
        ]
      end

      it 'returns parsed clusters data' do
        expect(subject.fetch).to eq(expected_response)
      end
    end

    context 'when regex passed' do
      let(:regex) { '^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}' } # ip address

      let(:expected_response) do
        [
          {
            :cluster_id=>"",
            :cluster_size=>nil,
            :domain=>"127.0.0.1",
            :global_volume=>124,
            :is_pending=>false,
            :categories=>[],
            :platform=>"NGFW"
          }
        ]
      end

      it 'returns parsed clusters data' do
        expect(subject.fetch).to eq(expected_response)
      end
    end
  end
end
