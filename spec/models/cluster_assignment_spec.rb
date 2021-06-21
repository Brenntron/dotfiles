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
      subject { described_class.fetch_assignments_for(clusters: cluster_ids) }

      let(:cluster_ids) { ['1', '2', '3'] }

      context 'when all assignments created less than 1 hour ago' do
        before do
          cluster_ids.each do |cluster_id|
            FactoryBot.create(:cluster_assignment, user_id: user.id, cluster_id: cluster_id)
          end
          # create extra assignment
          FactoryBot.create(:cluster_assignment, user_id: user.id, cluster_id: 4)
        end

        it 'returns cluster_assignments for given ids' do
          expect(subject.count).to be 3
        end
      end

      context 'when there is an assignment older than 1 hour' do
        before do
          FactoryBot.create(:cluster_assignment, user_id: user.id, cluster_id: 1)
          FactoryBot.create(:cluster_assignment, user_id: user.id, cluster_id: 2)
          FactoryBot.create(:cluster_assignment, :expired, user_id: user.id, cluster_id: 3)
        end

        it 'removes outdated assignments' do
          subject
          expect(described_class.where(cluster_id: cluster_ids).count).to be 2
        end

        it 'returns cluster_assignments for given ids' do
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
    subject { described_class.assign(cluster_ids, user) }
    let(:cluster_ids) { ['1'] }

    context 'when cluster is not assigned' do
      it 'assigns cluster to the user' do
        expect { subject }.to change { ClusterAssignment.count }.to(1)
      end
    end

    context 'when cluster is already assigned' do
      context 'when assignment is actual' do
        before { FactoryBot.create(:cluster_assignment, user_id: user.id, cluster_id: cluster_ids.first) }

        it 'rasises an exception' do
          expect { subject }.to raise_error(RuntimeError)
        end
      end

      context 'when assignment is expired' do
        before do
          FactoryBot.create(:cluster_assignment, :expired, user_id: user.id, cluster_id: cluster_ids.first)
        end

        it 'assigns cluster to the user' do
          subject
          expect(ClusterAssignment.count).to be 1
        end
      end
    end
  end

  describe '#assign!' do
    subject { described_class.assign!(cluster_ids, user) }
    let(:cluster_ids) { [1] }

    context 'when cluster is not assigned' do
      it 'assigns cluster to the user' do
        expect { subject }.to change { ClusterAssignment.count }.to(1)
      end
    end

    context 'when cluster is already assigned' do
      before { FactoryBot.create(:cluster_assignment, user_id: another_user.id, cluster_id: cluster_ids.first) }

      let(:another_user) { FactoryBot.create(:user) }

      it 'assigns cluster to the user anyway and drops previous assignment' do
        expect { subject }.to_not change { ClusterAssignment.count }
        expect(ClusterAssignment.where(user_id: user.id).count).to be 1
      end
    end
  end

  describe '#unassign' do
    subject { described_class.unassign(cluster_ids, user) }
    let(:cluster_ids) { ['1'] }

    before { FactoryBot.create(:cluster_assignment, user_id: user.id, cluster_id: cluster_ids.first) }

    it 'removes assignment' do
      expect { subject }.to change { ClusterAssignment.count }.to(0)
    end
  end

  describe '#assign_pemanent!' do
    subject { described_class.assign_pemanent!(cluster_ids, user) }
    let(:cluster_ids) { ['1'] }

    context 'when cluster is not assigned' do
      it 'creates permanent assignment for the user' do
        expect { subject }.to change { ClusterAssignment.count }.to(1)
        expect(ClusterAssignment.last.permanent).to be_truthy
      end
    end

    context 'when cluster is already assigned' do
      before { FactoryBot.create(:cluster_assignment, user_id: user.id, cluster_id: cluster_ids.first) }

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
end
