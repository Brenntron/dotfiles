describe Clusters::Ngfw::Processor do
  subject(:processor) { described_class.new(cluster, user) }

  before do
    allow(Wbrs::Prefix).to receive(:create_from_url).and_return(true)
  end

  let(:cluster) do
    {
      comment: 'hello',
      user: user.cvs_username,
      cluster_id: 1,
      categories: ['1', '2'],
      domain: 'example.com',
      is_important: true
    }
  end
  let(:user) { FactoryBot.create(:user) }

  describe 'process_2nd_person_review' do
    subject { processor.process_2nd_person_review }
    before { FactoryBot.create(:ngfw_cluster, domain: cluster[:domain]) }

    it 'creates ClusterAssignment instead of cluster proccessing' do
      expect(Wbrs::Prefix).not_to receive(:create_from_url)
      subject
      ngfw_cluster = NgfwCluster.find_by(domain: cluster[:domain])
      expect(ngfw_cluster.category_ids).not_to be_empty
      expect(ngfw_cluster.pending?).to be_truthy
    end
  end

  describe 'process' do
    subject { processor.process }
    before { FactoryBot.create(:ngfw_cluster, domain: cluster[:domain], category_ids: cluster[:categories].to_json) }

    it 'processes the cluster' do
      expect(Wbrs::Prefix).to receive(:create_from_url)
      subject
      ngfw_cluster = NgfwCluster.find_by(domain: cluster[:domain])
      expect(ngfw_cluster.processed?).to be_truthy
    end
  end

  describe 'decline' do
    subject { processor.decline }
    before { FactoryBot.create(:ngfw_cluster, domain: cluster[:domain], category_ids: cluster[:categories].to_json) }

    before do
      FactoryBot.create(:cluster_categorization, cluster_id: 1, user_id: user.id)
    end

    it 'removes ClusterCategorization for cluster' do
      subject
      ngfw_cluster = NgfwCluster.find_by(domain: cluster[:domain])
      expect(ngfw_cluster.category_ids).to be_empty
      expect(ngfw_cluster.created?).to be_truthy
    end

    it 'assigns cluster to user who declined the categorization' do
      expect { subject }.to change { ClusterAssignment.count }.to(1)
    end
  end
end
