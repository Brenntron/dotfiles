require 'rails_helper'

RSpec.describe Clusters::Importer, type: :model do
  describe '.import_without_delay' do
    let!(:ngfw_platform) { FactoryBot.create(:platform, internal_name: 'ngfw') }
    let!(:umbrella_platform) { FactoryBot.create(:platform, internal_name: 'umbrella') }
    let(:csv_data) do
      [
        { 'platform' => 'Umbrella', 'cluster_domain' => 'www.cisco.com', 'global_volume' => 100 },
        { 'platform' => 'SecureFirewall', 'cluster_domain' => 'whiskey.com', 'global_volume' => 200 },
        { 'platform' => 'SecureFirewall', 'cluster_domain' => 'whiskey.com', 'global_volume' => 200 }
      ]
    end

    before do
      FactoryBot.create(:ngfw_cluster, domain: 'existing_ngfw_cluster')
      FactoryBot.create(:umbrella_cluster, domain: 'existing_umbrella_cluster')
      allow(Clusters::DataFetcher).to receive(:fetch).and_return(csv_data)
    end
    it 'destroys existing clusters and imports new clusters' do
      Clusters::Importer.import_without_delay
      expect(NgfwCluster.exists?(domain: 'existing_ngfw_cluster')).to be_falsey
      expect(UmbrellaCluster.exists?(domain: 'existing_umbrella_cluster')).to be_falsey

      expect(UmbrellaCluster.exists?(domain: 'cisco.com')).to be_truthy
      expect(NgfwCluster.exists?(domain: 'whiskey.com')).to be_truthy
      expect(NgfwCluster.count).to eq(1)
    end
  end
end
