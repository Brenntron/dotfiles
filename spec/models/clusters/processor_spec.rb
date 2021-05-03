describe Clusters::Processor do
  subject { described_class.new(clusters, user) }

  before do
    allow(Clusters::Wbnp::Processor).to receive_message_chain(:new).and_return(
      double(
        processable?: processable,
        process_2nd_person_review: double,
        process: double,
        process!: double,
        decline!: double
      )
    )
  end

  let(:user) { FactoryBot.create(:user) }
  let(:processable) { true }
  let(:is_important) { false }

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
        :is_important => is_important,
        :is_pending => false,
        :platform => platform
      }
    ]
  end

  describe '.process' do
    context 'when clusters are processable' do
      context 'when clusters are important' do
        let(:is_important) { true }

        context 'WBNP clusters' do
          let(:platform) { 'WSA' }
          it 'process cluster to 2nd person review' do
            expect(Clusters::Wbnp::Processor).to receive_message_chain(:new, :process_2nd_person_review)
            subject.process
          end
        end
      end

      context 'when clusters are not important' do
        context 'WBNP clusters' do
          let(:platform) { 'WSA' }

          it 'processes clusters' do
            expect(Clusters::Wbnp::Processor).to receive_message_chain(:new, :process)
            subject.process
          end
        end
      end
    end

    context 'when clusters are not processable' do
      let(:processable) { false }

      context 'WBNP clusters' do
        let(:platform) { 'WSA' }

        it 'does not call any processor' do
          wbnp_processor = Clusters::Wbnp::Processor.new(clusters, user)
          expect(wbnp_processor).not_to receive(:process_2nd_person_review)
          expect(wbnp_processor).not_to receive(:process)
          subject.process
        end
      end
    end
  end

  describe '.process!' do
    context 'WBNP clusters' do
      let(:platform) { 'WSA' }
      it 'calls process! for wbnp processor' do
        expect(Clusters::Wbnp::Processor).to receive_message_chain(:new, :process!)
        subject.process!
      end
    end
  end

  describe '.decline!' do
    context 'WBNP clusters' do
      let(:platform) { 'WSA' }
      it 'calls decline! for wbnp processor' do
        expect(Clusters::Wbnp::Processor).to receive_message_chain(:new, :decline!)
        subject.decline!
      end
    end
  end
end
