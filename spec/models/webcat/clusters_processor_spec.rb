describe Webcat::ClustersProcessor do
  before do
    allow(Wbrs::Cluster).to receive(:process).and_return(true)
  end

  let(:user) { FactoryBot.create(:user) }

  describe 'process' do
    subject { described_class.process(clusters_data, user) }

    context 'when cluster is important' do
      let(:clusters_data) do
        [
          {
            comment: 'hello',
            user: user.cvs_username,
            cluster_id: 1,
            cat_ids: ['1', '2'],
            domain: 'example.com',
            is_important: true
          }
        ]
      end

      it 'creates ClusterAssignment instead of cluster proccessing' do
        expect(Wbrs::Cluster).not_to receive(:process)
        expect { subject }.to change { ClusterCategorization.count }.to(1)
      end
    end

    context 'when cluster is not important' do
      let(:clusters_data) do
        [
          {
            comment: 'hello',
            user: user.cvs_username,
            cluster_id: 1,
            cat_ids: ['1', '2'],
            domain: 'example.com',
            is_important: false
          }
        ]
      end

      it 'processes the cluster' do
        expect(Wbrs::Cluster).to receive(:process)
        expect { subject }.to_not change { ClusterCategorization.count }
      end
    end
  end

  describe 'process!' do
    subject { described_class.process!(cluster_ids) }

    let(:cluster_ids) { [1] }

    before do
      FactoryBot.create(:cluster_categorization, cluster_id: 1, user_id: user.id)
    end

    it 'processes cluster with no conditions' do
      expect(Wbrs::Cluster).to receive(:process)
      expect { subject }.to change { ClusterCategorization.count }.to(0)
    end
  end

  describe 'decline!' do
    subject { described_class.decline!(cluster_ids, user) }

    let(:cluster_ids) { [1] }

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
