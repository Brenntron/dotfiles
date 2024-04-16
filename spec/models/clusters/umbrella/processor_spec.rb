describe Clusters::Umbrella::Processor do
  subject(:processor) { described_class.new(clusters, user) }
  before { allow(Wbrs::Prefix).to receive(:create_from_url).and_return(true) }

  let(:clusters) { [cluster] }
  let(:user) { FactoryBot.create(:user) }
  let(:cluster) do
    {
      comment: 'hello',
      user: user.cvs_username,
      cluster_id: 1,
      categories: %w[1 2],
      domain: 'example.com',
      is_important: true
    }
  end

  describe 'process_2nd_person_review' do
    let!(:umbrella_cluster) { FactoryBot.create(:cluster, :umbrella, domain: cluster[:domain]) }

    it 'creates ClusterAssignment instead of cluster processing' do
      expect(Wbrs::Prefix).not_to receive(:create_from_url)
      expect(umbrella_cluster.category_ids).to be_nil
      expect(umbrella_cluster.pending?).to be_falsey

      processor.send(:process_2nd_person_review, cluster)
      umbrella_cluster.reload

      expect(umbrella_cluster.category_ids).to eq cluster[:categories].map(&:to_i).to_json
      expect(umbrella_cluster.pending?).to be_truthy
    end
  end

  describe 'process' do
    let!(:umbrella_cluster) { FactoryBot.create(:cluster, :umbrella, domain: cluster[:domain]) }

    context 'if cluster is not important' do
      before { cluster[:is_important] = false }

      it 'creates ClusterAssignment instead of cluster processing' do
        expect(Wbrs::Prefix).to receive(:create_from_url)
        expect(umbrella_cluster.processed?).to be_falsey
        expect(umbrella_cluster.comment).to be_nil

        processor.process
        umbrella_cluster.reload
        expect(umbrella_cluster.processed?).to be_truthy
        expect(umbrella_cluster.comment).to eq cluster[:comment]
      end
    end

    context 'if cluster is important' do
      it 'processes the cluster' do
        expect(Wbrs::Prefix).to_not receive(:create_from_url)
        expect(umbrella_cluster.category_ids).to be_nil
        expect(umbrella_cluster.pending?).to be_falsey

        processor.process
        umbrella_cluster.reload

        expect(umbrella_cluster.category_ids).to eq cluster[:categories].map(&:to_i).to_json
        expect(umbrella_cluster.pending?).to be_truthy
      end
    end
  end

  describe 'decline' do
    let!(:umbrella_cluster) do
      FactoryBot.create(:cluster, :umbrella, domain: cluster[:domain],
                                           category_ids: cluster[:categories],
                                           status: :pending)
    end

    it 'removes ClusterCategorization for cluster' do
      expect(umbrella_cluster.created?).to be_falsey

      processor.decline
      umbrella_cluster.reload

      expect(umbrella_cluster.category_ids).to be_empty
      expect(umbrella_cluster.created?).to be_truthy
    end

    it 'assigns cluster to user who declined the categorization' do
      expect { processor.decline }.to change { ClusterAssignment.count }.by(1)
    end
  end
end
