describe Clusters::Wbnp::Assignor do
  subject { described_class.new(cluster, user) }

  before do
    allow(ClusterAssignment).to receive(:assign).and_return(double)
    allow(ClusterAssignment).to receive(:assign!).and_return(double)
    allow(ClusterAssignment).to receive(:unassign).and_return(double)
  end

  let(:cluster) do
    {
      :age => '3 months, 1 week, 3 days, 11 hours, and 6 minutes',
      :assigned_to => '',
      :categories => [],
      :cluster_id => 1,
      :cluster_size => 2,
      :ctime => 'Fri, 21 Sep 2018 12:53:40 GMT',
      :domain => 'googletest.com',
      :global_volume => 7637758,
      :is_important => true,
      :is_pending => false,
      :platform => 'WSA'
    }
  end
  let(:user) { FactoryBot.create(:user) }

  describe '.assign' do
    it 'calls ClusterAssignment#assign' do
      expect(ClusterAssignment).to receive(:assign)
      subject.assign
    end
  end

  describe '.assign!' do
    it 'calls ClusterAssignment#assign!' do
      expect(ClusterAssignment).to receive(:assign!)
      subject.assign!
    end
  end

  describe '.unassign' do
    it 'calls ClusterAssignment#unassign' do
      expect(ClusterAssignment).to receive(:unassign)
      subject.unassign
    end
  end
end
