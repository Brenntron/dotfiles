describe Webcat::ClustersProcessor do
  before do
    allow(Wbrs::Cluster).to receive(:process).and_return(true)
    allow(Wbrs::Cluster).to receive(:retrieve).and_return([{ 'url' => 'http://example.com' }])
  end

  let!(:main_webcat_manager) { FactoryBot.create(:user, cvs_username: Complaint::MAIN_WEBCAT_MANAGER_CONTACT) }
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
    subject { described_class.process!(cluster_ids, user) }

    let(:cluster_ids) { [1] }

    before do
      FactoryBot.create(:cluster_categorization, cluster_id: 1, user_id: user.id)
      allow(Webcat::EntryVerdictChecker).to receive_message_chain(:new, :check).and_return(
        {
          verdict_pass: verdict_pass,
          verdict_reasons: 'whatever reasons'
        }
      )
    end

    context 'when 3rd person review is not needed' do
      context 'when verdict check passed' do
        let(:verdict_pass) { true }

        it 'processes cluster' do
          expect(Wbrs::Cluster).to receive(:process)
          expect { subject }.to change { ClusterCategorization.count }.to(0)
        end
      end

      context 'when user is webcat manager' do
        before { user.roles << FactoryBot.create(:web_cat_manager_role) }
        let(:verdict_pass) { false }

        it 'processes cluster' do
          expect(Wbrs::Cluster).to receive(:process)
          expect { subject }.to change { ClusterCategorization.count }.to(0)
        end
      end
    end

    context 'when 3rd person review needed' do
      context 'when verdict check not passed' do
        let(:verdict_pass) { false }

        it 'processes cluster' do
          expect(Wbrs::Cluster).not_to receive(:process)
          expect { subject }.to raise_error(RuntimeError)
          expect(ClusterAssignment.last.user_id).to eq(main_webcat_manager.id)
        end
      end
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
