describe Clusters::Wbnp::Processor do
  subject(:processor) { described_class.new(cluster, user) }

  before do
    allow(Wbrs::Cluster).to receive(:process).and_return(true)
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

    it 'creates ClusterAssignment instead of cluster proccessing' do
      expect(Wbrs::Cluster).not_to receive(:process)
      expect { subject }.to change { ClusterCategorization.count }.to(1)
    end
  end

  describe 'process' do
    subject { processor.process }

    it 'processes the cluster' do
      expect(Wbrs::Cluster).to receive(:process)
      expect { subject }.to_not change { ClusterCategorization.count }
    end
  end

  describe 'decline' do
    subject { processor.decline }

    before do
      FactoryBot.create(:cluster_categorization, cluster_id: 1, user_id: user.id)
    end

    it 'removes ClusterCategorization for cluster' do
      expect { subject }.to change { ClusterCategorization.count }.to(0)
    end

    it 'assigns cluster to user who declined the categorization' do
      expect { subject }.to change { ClusterAssignment.count }.to(1)
    end
  end
end
