describe ClusterCategorization do
  let(:user) { FactoryBot.create(:user) }
  let(:another_user) { FactoryBot.create(:user) }

  describe '#get_categorized_cluster_ids_for' do
    subject { described_class.get_categorized_cluster_ids_for(user) }

    let!(:user_categorization) { FactoryBot.create(:cluster_categorization, user_id: user.id, cluster_id: 1) }
    let!(:another_user_categorization) { FactoryBot.create(:cluster_categorization, user_id: another_user.id, cluster_id: 2) }

    it 'returns cluster ids for the user' do
      expect(subject.count).to be 1
      expect(subject.first).to eq(user_categorization.cluster_id)
    end
  end
end
