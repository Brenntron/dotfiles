describe ClusterAssignment do
  let(:user) { FactoryBot.create(:user) }

  describe '#fetch_assignments_for' do
    context 'feching user assignments' do
      subject { described_class.fetch_assignments_for(user: user) }

      context 'when all assignments created less than 1 hour ago' do
        before { FactoryBot.create_list(:cluster_assignment, 3, user_id: user.id, cluster_id: rand(10)) }

        it 'returns all assignments for the user' do
          expect(subject.count).to be 3
        end
      end

      context 'when there is an assignment older than 1 hour' do
        before do
          FactoryBot.create_list(:cluster_assignment, 2, user_id: user.id, cluster_id: rand(10))
          FactoryBot.create(:cluster_assignment, :expired, user_id: user.id, cluster_id: rand(10))
        end

        it 'deletes outdated assignments' do
          subject
          expect(described_class.where(user_id: user.id).count).to be 2
        end

        it 'returns only actual assignments' do
          expect(subject.count).to be 2
        end
      end
    end

    context 'fetching cluster assignments' do
      subject { described_class.fetch_assignments_for(domains: cluster_domains) }

      let(:cluster_domains) { ['example.com', '127.0.0.1', 'google.com'] }

      context 'when all assignments created less than 1 hour ago' do
        before do
          cluster_domains.each do |domain|
            FactoryBot.create(:cluster_assignment, user_id: user.id, domain: domain)
          end
          # create extra assignment
          FactoryBot.create(:cluster_assignment, user_id: user.id, domain: 'some.thing')
        end

        it 'returns cluster_assignments for given domains' do
          expect(subject.count).to be 3
        end
      end

      context 'when there is an assignment older than 1 hour' do
        before do
          FactoryBot.create(:cluster_assignment, user_id: user.id, domain: 'example.com')
          FactoryBot.create(:cluster_assignment, user_id: user.id, domain: '127.0.0.1')
          FactoryBot.create(:cluster_assignment, :expired, user_id: user.id, domain: 'google.com')
        end

        it 'removes outdated assignments' do
          subject
          expect(described_class.where(domain: cluster_domains).count).to be 2
        end

        it 'returns cluster_assignments for given domains' do
          expect(subject.count).to be 2
        end
      end
    end
  end

  describe '#fetch_all_assignments' do
    subject { described_class.fetch_all_assignments }

    context 'where all assignments are not expired' do
      before { FactoryBot.create_list(:cluster_assignment, 2, user_id: user.id) }

      it 'returns all cluster assignments' do
        expect(subject.count).to eq 2
      end
    end

    context 'where all assignments are valid' do
      before do
        FactoryBot.create(:cluster_assignment, user_id: user.id)
        FactoryBot.create(:cluster_assignment, :expired, user_id: user.id)
      end

      it 'returns only non-expired cluster assignments' do
        expect(subject.count).to eq 1
      end
    end
  end

  describe '#assign' do
    subject { described_class.assign(cluster, user) }
    let(:cluster) { { domain: 'example.com' } }

    context 'when cluster is not assigned' do
      it 'assigns cluster to the user' do
        expect { subject }.to change { ClusterAssignment.count }.to(1)
      end
    end

    context 'when cluster is already assigned' do
      context 'when assignment is actual' do
        before { FactoryBot.create(:cluster_assignment, user_id: user.id, domain: cluster[:domain]) }

        it 'rasises an exception' do
          expect { subject }.to raise_error(RuntimeError)
        end
      end

      context 'when assignment is expired' do
        before do
          FactoryBot.create(:cluster_assignment, :expired, user_id: user.id, domain: cluster[:domain])
        end

        it 'assigns cluster to the user' do
          subject
          expect(ClusterAssignment.count).to be 1
        end
      end
    end
  end

  describe '#assign!' do
    subject { described_class.assign!(cluster, user) }
    let(:cluster) { { domain: 'example.com' } }

    context 'when cluster is not assigned' do
      it 'assigns cluster to the user' do
        expect { subject }.to change { ClusterAssignment.count }.to(1)
      end
    end

    context 'when cluster is already assigned' do
      before { FactoryBot.create(:cluster_assignment, user_id: another_user.id, domain: cluster[:domain]) }

      let(:another_user) { FactoryBot.create(:user) }

      it 'assigns cluster to the user anyway and drops previous assignment' do
        expect { subject }.to_not change { ClusterAssignment.count }
        expect(ClusterAssignment.where(user_id: user.id).count).to be 1
      end
    end
  end

  describe '#unassign' do
    subject { described_class.unassign(cluster, user) }
    let(:cluster) { { domain: 'example.com' } }

    before { FactoryBot.create(:cluster_assignment, user_id: user.id, domain: cluster[:domain]) }

    it 'removes assignment' do
      expect { subject }.to change { ClusterAssignment.count }.to(0)
    end
  end

  describe '#assign_pemanent!' do
    subject { described_class.assign_pemanent!(cluster, user) }
    let(:cluster) { { domain: 'example.com' } }

    context 'when cluster is not assigned' do
      it 'creates permanent assignment for the user' do
        expect { subject }.to change { ClusterAssignment.count }.to(1)
        expect(ClusterAssignment.last.permanent).to be_truthy
      end
    end

    context 'when cluster is already assigned' do
      before { FactoryBot.create(:cluster_assignment, user_id: user.id, domain: cluster[:domain]) }

      it 'assigns cluster to the user anyway and drops previous assignment' do
        expect { subject }.to_not change { ClusterAssignment.count }
        expect(ClusterAssignment.where(user_id: user.id).count).to be 1
        expect(ClusterAssignment.last.permanent).to be_truthy
      end
    end
  end

  describe 'destroy_expired_assignments!' do
    subject { described_class.send(:destroy_expired_assignments!) }

    context 'permanent assignments' do
      before do
        FactoryBot.create(:cluster_assignment, :expired, user_id: user.id)
        FactoryBot.create(:cluster_assignment, :expired, :permanent, user_id: user.id)
      end

      it 'should not remove expired permanent attachments' do
        expect { subject }.to change { ClusterAssignment.count }.to(1)
      end
    end
  end

  describe 'get_assigned_cluster_ids_for' do
    subject { described_class.get_assigned_cluster_ids_for(user) }

    let(:another_user) { FactoryBot.create(:user) }
    let!(:user_assignment) { FactoryBot.create(:cluster_assignment, user_id: user.id, cluster_id: 1) }
    let!(:another_user_assignment) { FactoryBot.create(:cluster_assignment, user_id: another_user.id, cluster_id: 2) }

    it 'returns cluster ids for the user' do
      expect(subject.count).to be 1
      expect(subject.first).to eq(user_assignment.cluster_id)
    end
  end

  describe 'get_assigned_cluster_domains_for' do
    subject { described_class.get_assigned_cluster_domains_for(user) }

    let(:another_user) { FactoryBot.create(:user) }
    let!(:user_assignment) { FactoryBot.create(:cluster_assignment, user_id: user.id, domain: 'example.com') }
    let!(:another_user_assignment) { FactoryBot.create(:cluster_assignment, user_id: another_user.id, domain: '127.0.0.1') }

    it 'returns cluster domains for the user' do
      expect(subject.count).to be 1
      expect(subject.first).to eq(user_assignment.domain)
    end
  end
end
