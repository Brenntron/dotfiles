describe Clusters::Ngfw::Processor do
  subject(:processor) { described_class.new(clusters, user) }

  before do
    allow(Wbrs::Prefix).to receive(:create_from_url).and_return(true)
  end

  let(:clusters) { [cluster] }
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
    let!(:ngfw_cluster) { FactoryBot.create(:ngfw_cluster, domain: cluster[:domain]) }

    it 'creates ClusterAssignment instead of cluster processing' do
      expect(Wbrs::Prefix).not_to receive(:create_from_url)
      expect(ngfw_cluster.category_ids).to be_nil
      expect(ngfw_cluster.pending?).to be_falsey

      processor.send(:process_2nd_person_review, cluster)
      ngfw_cluster.reload

      expect(ngfw_cluster.category_ids).not_to be_empty
      expect(ngfw_cluster.pending?).to be_truthy
    end
  end

  describe 'process' do
    let!(:ngfw_cluster) { FactoryBot.create(:ngfw_cluster, domain: cluster[:domain]) }

    context 'if cluster is not important' do
      before { cluster[:is_important] = false }

      it 'processes the cluster' do
        expect(Wbrs::Prefix).to receive(:create_from_url)
        expect(ngfw_cluster.processed?).to be_falsey
        expect(ngfw_cluster.comment).to be_nil

        processor.process
        ngfw_cluster.reload

        expect(ngfw_cluster.processed?).to be_truthy
        expect(ngfw_cluster.comment).to eq cluster[:comment]
      end
    end

    context 'if cluster is important' do
      it 'creates ClusterAssignment instead of cluster processing' do
        expect(Wbrs::Prefix).to_not receive(:create_from_url)
        expect(ngfw_cluster.category_ids).to be_nil
        expect(ngfw_cluster.pending?).to be_falsey

        processor.process
        ngfw_cluster.reload

        expect(ngfw_cluster.category_ids).to eq cluster[:categories].map(&:to_i).to_json
        expect(ngfw_cluster.pending?).to be_truthy
      end
    end
  end

  describe 'decline' do
    subject { processor.decline }

    let!(:ngfw_cluster) do
      FactoryBot.create(:ngfw_cluster, domain: cluster[:domain],
                                       category_ids: cluster[:categories].to_json,
                                       status: :processed)
    end

    let!(:categorization) do
      FactoryBot.create(:cluster_categorization, cluster_id: ngfw_cluster.id, user_id: user.id)
    end


    it 'removes ClusterCategorization for cluster' do
      expect(ngfw_cluster.category_ids).to eq cluster[:categories].to_json
      expect(ngfw_cluster.created?).to be_falsey

      processor.decline
      ngfw_cluster.reload

      expect(ngfw_cluster.category_ids).to be_empty
      expect(ngfw_cluster.created?).to be_truthy
    end

    it 'assigns cluster to user who declined the categorization' do
      expect { processor.decline }.to change { ClusterAssignment.count }.by(1)
    end
  end
end
