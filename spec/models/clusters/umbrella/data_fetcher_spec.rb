describe Clusters::Umbrella::DataFetcher do
  subject { described_class.new(regex, filter, user) }

  let(:regex) { nil }
  let(:user) { FactoryBot.create(:user) }
  let(:another_user) { FactoryBot.create(:user) }
  let(:filter) { {} }

  before do
    FactoryBot.create(:cluster, :umbrella, domain: '127.0.0.1')
    FactoryBot.create(:cluster, :umbrella, domain: 'example.com')
  end

  describe '.fetch' do
    context 'when regex is blank' do
      let(:expected_response) do
        [
          {
            cluster_id: '',
            cluster_size: nil,
            domain: '127.0.0.1',
            global_volume: 0,
            is_pending: false,
            categories: [],
            platform: 'Umbrella'
          },
          {
            cluster_id: '',
            cluster_size: nil,
            domain: 'example.com',
            global_volume: 0,
            is_pending: false,
            categories: [],
            platform: 'Umbrella'
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
            cluster_id: '',
            cluster_size: nil,
            domain: '127.0.0.1',
            global_volume: 0,
            is_pending: false,
            categories: [],
            platform: 'Umbrella'
          }
        ]
      end

      it 'returns parsed clusters data' do
        expect(subject.fetch).to eq(expected_response)
      end
    end

    describe 'filter' do
      context 'my filter' do
        let(:filter) { { f: 'my' } }

        before do
          FactoryBot.create(:cluster_assignment, domain: 'example.com', user_id: user.id)
          FactoryBot.create(:cluster_assignment, domain: '127.0.0.1', user_id: another_user.id)
        end

        let(:expected_response) do
          [
            {
              cluster_id: '',
              cluster_size: nil,
              domain: 'example.com',
              global_volume: 0,
              is_pending: false,
              categories: [],
              platform: 'Umbrella'
            }
          ]
        end

        it 'returns only my assigned clusters' do
          expect(subject.fetch).to eq(expected_response)
        end
      end

      context 'pending filter' do
        let(:filter) { { f: 'pending' } }

        before { WebCatCluster.umbrella.last.pending! }

        let(:expected_response) do
          [
            {
              cluster_id: '',
              cluster_size: nil,
              domain: 'example.com',
              global_volume: 0,
              is_pending: true,
              categories: [],
              platform: 'Umbrella'
            }
          ]
        end

        it 'returns only categorized clusters' do
          expect(subject.fetch).to eq(expected_response)
        end
      end
    end
  end
end
