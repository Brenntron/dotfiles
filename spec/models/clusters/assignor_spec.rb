describe Clusters::Assignor do
  subject { described_class.new(clusters, user) }

  before do
    allow(ClusterAssignment).to receive(:assign).and_return(double)
    allow(ClusterAssignment).to receive(:unassign).and_return(double)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:clusters) do
    [
      {
        :cluster_id => 1,
        :domain => 'googletest.com'
      }
    ]
  end

  describe '.assign' do
    it 'calls WBNP assignor' do
      expect(ClusterAssignment).to receive(:assign)
      subject.assign
    end
  end

  describe '.unassign' do
    it 'calls WBNP assignor' do
      expect(ClusterAssignment).to receive(:unassign)
      subject.unassign
    end
  end
end
