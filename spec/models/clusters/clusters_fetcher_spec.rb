describe Clusters::ClustersFetcher do
  subject { described_class.new(filter, regex, user) }

  before do
    allow(Clusters::Wbnp::DataFetcher).to receive_message_chain(:new, :fetch).and_return(wbnp_clusters)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:regex) { nil }

  let(:wbnp_clusters) do
    [
      {
        :age => "3 months, 1 week, 3 days, 11 hours, and 6 minutes",
        :assigned_to => "",
        :categories => [],
        :cluster_id => 1,
        :cluster_size => 2,
        :ctime => "Fri, 21 Sep 2018 12:53:40 GMT",
        :domain => "googletest.com",
        :global_volume => 7637758,
        :is_important => true,
        :is_pending => false,
        :platform => "WSA"
      },
      {
        :age => "3 months, 1 week, 2 days, 11 hours, and 6 minutes",
        :assigned_to => "",
        :categories => [],
        :cluster_id => 2,
        :cluster_size => 2,
        :ctime => "Sat, 22 Sep 2018 12:53:40 GMT",
        :domain => "127.0.0.1",
        :global_volume => 7637759,
        :is_important => true,
        :is_pending => false,
        :platform => "WSA"
      }
    ]
  end

  let(:expected_response) { [wbnp_clusters].flatten }

  describe '.fetch' do
    context 'when no filter passed' do
      let(:filter) { nil }

      it 'should return all clusters' do
        expect(Clusters::Wbnp::DataFetcher).to receive_message_chain(:new, :fetch)
        expect(subject.fetch).to eq(expected_response)
      end
    end

    describe 'user specific filters' do
      describe 'all filter' do
        let(:filter) { 'all' }

        it 'shoud return all clusters' do
          expect(subject.fetch).to eq(expected_response)
        end
      end

      describe 'my filter' do
        let(:filter) { 'my' }

        let(:wbnp_clusters) do
          [
            {
              :age => "3 months, 1 week, 3 days, 11 hours, and 6 minutes",
              :assigned_to => user.cvs_username,
              :categories => [],
              :cluster_id => 1,
              :cluster_size => 2,
              :ctime => "Fri, 21 Sep 2018 12:53:40 GMT",
              :domain => "googletest.com",
              :global_volume => 7637758,
              :is_important => true,
              :is_pending => false,
              :platform => "WSA"
            },
            {
              :age => "3 months, 1 week, 2 days, 11 hours, and 6 minutes",
              :assigned_to => "",
              :categories => [],
              :cluster_id => 2,
              :cluster_size => 2,
              :ctime => "Sat, 22 Sep 2018 12:53:40 GMT",
              :domain => "127.0.0.1",
              :global_volume => 7637759,
              :is_important => true,
              :is_pending => false,
              :platform => "WSA"
            }
          ]
        end

        let(:expected_response) do
          [
            {
              :age => "3 months, 1 week, 3 days, 11 hours, and 6 minutes",
              :assigned_to => user.cvs_username,
              :categories => [],
              :cluster_id => 1,
              :cluster_size => 2,
              :ctime => "Fri, 21 Sep 2018 12:53:40 GMT",
              :domain => "googletest.com",
              :global_volume => 7637758,
              :is_important => true,
              :is_pending => false,
              :platform => "WSA"
            }
          ]
        end

        it 'returns only assigned cluster' do
          expect(subject.fetch).to eq(expected_response)
        end
      end

      describe 'unassigned filter' do
        let(:filter) { 'unassigned' }

        let(:wbnp_clusters) do
          [
            {
              :age => "3 months, 1 week, 3 days, 11 hours, and 6 minutes",
              :assigned_to => user.cvs_username,
              :categories => [],
              :cluster_id => 1,
              :cluster_size => 2,
              :ctime => "Fri, 21 Sep 2018 12:53:40 GMT",
              :domain => "googletest.com",
              :global_volume => 7637758,
              :is_important => true,
              :is_pending => false,
              :platform => "WSA"
            },
            {
              :age => "3 months, 1 week, 2 days, 11 hours, and 6 minutes",
              :assigned_to => "",
              :categories => [],
              :cluster_id => 2,
              :cluster_size => 2,
              :ctime => "Sat, 22 Sep 2018 12:53:40 GMT",
              :domain => "127.0.0.1",
              :global_volume => 7637759,
              :is_important => true,
              :is_pending => false,
              :platform => "WSA"
            }
          ]
        end

        let(:expected_response) do
          [
            {
              :age => "3 months, 1 week, 2 days, 11 hours, and 6 minutes",
              :assigned_to => "",
              :categories => [],
              :cluster_id => 2,
              :cluster_size => 2,
              :ctime => "Sat, 22 Sep 2018 12:53:40 GMT",
              :domain => "127.0.0.1",
              :global_volume => 7637759,
              :is_important => true,
              :is_pending => false,
              :platform => "WSA"
            }
          ]
        end

        it 'returns only unassigned clusters' do
          expect(subject.fetch).to eq(expected_response)
        end
      end

      describe 'pending filter' do
        let(:filter) { 'pending' }

        let(:wbnp_clusters) do
          [
            {
              :age => "3 months, 1 week, 3 days, 11 hours, and 6 minutes",
              :assigned_to => user.cvs_username,
              :categories => [],
              :cluster_id => 1,
              :cluster_size => 2,
              :ctime => "Fri, 21 Sep 2018 12:53:40 GMT",
              :domain => "googletest.com",
              :global_volume => 7637758,
              :is_important => true,
              :is_pending => true,
              :platform => "WSA"
            },
            {
              :age => "3 months, 1 week, 2 days, 11 hours, and 6 minutes",
              :assigned_to => "",
              :categories => [],
              :cluster_id => 2,
              :cluster_size => 2,
              :ctime => "Sat, 22 Sep 2018 12:53:40 GMT",
              :domain => "127.0.0.1",
              :global_volume => 7637759,
              :is_important => true,
              :is_pending => false,
              :platform => "WSA"
            }
          ]
        end

        let(:expected_response) do
          [
            {
              :age => "3 months, 1 week, 3 days, 11 hours, and 6 minutes",
              :assigned_to => user.cvs_username,
              :categories => [],
              :cluster_id => 1,
              :cluster_size => 2,
              :ctime => "Fri, 21 Sep 2018 12:53:40 GMT",
              :domain => "googletest.com",
              :global_volume => 7637758,
              :is_important => true,
              :is_pending => true,
              :platform => "WSA"
            }
          ]
        end

        it 'returns only clusters with categorization' do
          expect(subject.fetch).to eq(expected_response)
        end
      end
    end
  end
end
