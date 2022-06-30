describe Clusters::Ngfw::DataFetcher do
  subject { described_class.new(regex, filter, user) }

  let(:regex) { nil }
  let(:user) { FactoryBot.create(:user) }
  let(:another_user) { FactoryBot.create(:user) }
  let(:filter) { {} }

  describe '.fetch' do
    let!(:ngfw_cluster_url) { FactoryBot.create(:ngfw_cluster, domain: 'example.com', traffic_hits: 123) }
    let!(:ngfw_cluster_ip) { FactoryBot.create(:ngfw_cluster, domain: '127.0.0.1', traffic_hits: 124) }

    let(:cluster_ip_response) do
      {
        cluster_id: '',
        cluster_size: nil,
        domain: ngfw_cluster_ip.domain,
        global_volume: ngfw_cluster_ip.traffic_hits,
        is_pending: false,
        categories: [],
        platform: 'NGFW'
      }
    end

    let(:cluster_url_response) do
      {
        cluster_id: '',
        cluster_size: nil,
        domain: ngfw_cluster_url.domain,
        global_volume: ngfw_cluster_url.traffic_hits,
        is_pending: false,
        categories: [],
        platform: 'NGFW'
      }
    end

    context 'when regex is blank' do
      let(:expected_response) { [cluster_ip_response, cluster_url_response] }

      it 'returns parsed clusters data' do
        expect(subject.fetch).to eq(expected_response)
      end
    end

    context 'when regex passed' do
      let(:regex) { '^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}' } # ip address

      let(:expected_response) { [cluster_ip_response] }

      it 'returns parsed clusters data' do
        expect(subject.fetch).to eq(expected_response)
      end
    end

    describe 'filter' do
      context 'my filter' do
        let(:filter) { { f: 'my' } }

        let!(:cluster_assigment_for_user) do
          FactoryBot.create(:cluster_assignment, domain: ngfw_cluster_url.domain, user_id: user.id)
        end

        let!(:cluster_assigment_for_another_user) do
          FactoryBot.create(:cluster_assignment, domain: ngfw_cluster_ip.domain, user_id: another_user.id)
        end

        let(:expected_response) { [cluster_url_response] }

        it 'returns only my assigned clusters' do
          expect(subject.fetch).to eq(expected_response)
        end
      end

      context 'pending filter' do
        let(:filter) { { f: 'pending' } }

        before do
          cluster_url_response[:is_pending] = true
          ngfw_cluster_url.pending!
        end

        let(:expected_response) { [cluster_url_response] }

        it 'returns only categorized clusters' do
          expect(subject.fetch).to eq(expected_response)
        end
      end
    end
  end
end
