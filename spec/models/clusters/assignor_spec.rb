describe Clusters::Assignor do
  subject { described_class.new(clusters, user) }

  before do
    allow(Clusters::Wbnp::Assignor).to receive_message_chain(:new, :assign).and_return(true)
    allow(Clusters::Wbnp::Assignor).to receive_message_chain(:new, :unassign).and_return(true)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:clusters) do
    [
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
        :platform => platform
      }
    ]
  end

  describe '.assign' do
    context 'when WBNP cluster' do
      let(:platform) { 'WSA' }

      it 'calls WBNP assignor' do
        expect(Clusters::Wbnp::Assignor).to receive_message_chain(:new, :assign)
        subject.assign
      end
    end
  end

  describe '.unassign' do
    context 'when WBNP cluster' do
      let(:platform) { 'WSA' }

      it 'calls WBNP assignor' do
        expect(Clusters::Wbnp::Assignor).to receive_message_chain(:new, :unassign)
        subject.unassign
      end
    end
  end
end
