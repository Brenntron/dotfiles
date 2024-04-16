require 'rails_helper'

RSpec.describe Clusters::Importer, type: :model do
  describe '.import_without_delay' do
    let!(:ngfw_platform) { FactoryBot.create(:platform, internal_name: 'ngfw') }
    let!(:umbrella_platform) { FactoryBot.create(:platform, internal_name: 'umbrella') }
    let!(:umbrella_platform) { FactoryBot.create(:platform, internal_name: 'meraki') }

    let(:csv_data) do
      [
        { 'platform' => 'Umbrella', 'cluster_domain' => 'www.cisco.com', 'global_volume' => 100 },
        { 'platform' => 'SecureFirewall', 'cluster_domain' => 'whiskey.com', 'global_volume' => 200 },
        { 'platform' => 'SecureFirewall', 'cluster_domain' => 'whiskey.com', 'global_volume' => 200 }
      ]
    end

    before do
      FactoryBot.create(:cluster, :ngfw, domain: 'existing_ngfw_cluster')
      FactoryBot.create(:cluster, :umbrella, domain: 'existing_umbrella_cluster')
      allow(Clusters::DataFetcher).to receive(:fetch).and_return(csv_data)
    end

    it 'destroys existing clusters and imports new clusters' do
      Clusters::Importer.import_without_delay
      expect(WebCatCluster.exists?(domain: 'existing_ngfw_cluster', cluster_type: 'Umberlla')).to be_falsey
      expect(WebCatCluster.exists?(domain: 'existing_umbrella_cluster', cluster_type: 'Umbrella')).to be_falsey

      expect(WebCatCluster.exists?(domain: 'cisco.com', cluster_type: 'Umbrella')).to be_truthy
      expect(WebCatCluster.exists?(domain: 'whiskey.com', cluster_type: 'NGFW')).to be_truthy
      expect(WebCatCluster.ngfw.count).to eq(1)
    end
  end
end
