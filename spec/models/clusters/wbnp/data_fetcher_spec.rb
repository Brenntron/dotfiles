describe Clusters::Wbnp::DataFetcher do
  subject { described_class.new(regex, filter, user) }

  let(:user) { FactoryBot.create(:user) }
  let(:filter) { {} }

  before do
    allow(Wbrs::Cluster).to receive(:where).and_return(clusters)

    Timecop.freeze(Time.zone.local(2019).in_time_zone('EST')) # freeze time to test time-related fields
  end
  after { Timecop.unfreeze }

  let(:clusters) do
    {
      'meta' => {"limit"=>1000, "rows_found"=>15161},
      'data' => [
        {
          'cluster_id'=>1,
          'domain'=>"googletest.com",
          'ctime'=>"Fri, 21 Sep 2018 12:53:40 GMT",
          'mtime'=>"Fri, 21 Sep 2018 12:53:40 GMT",
          'apac_volume'=>0,
          'emrg_volume'=>0,
          'eurp_volume'=>0,
          'japn_volume'=>0,
          'glob_volume'=>7637758,
          'cluster_size'=>2
        },
        {
          'cluster_id'=>2,
          'domain'=>"127.0.0.1",
          'ctime'=>"Sat, 22 Sep 2018 12:53:40 GMT",
          'mtime'=>"Sat, 22 Sep 2018 12:53:40 GMT",
          'apac_volume'=>0,
          'emrg_volume'=>0,
          'eurp_volume'=>0,
          'japn_volume'=>0,
          'glob_volume'=>7637759,
          'cluster_size'=>2
        }
      ]
    }
  end

  describe '.fetch' do
    let(:expected_response) do
      [
        {
          :categories=>[],
          :cluster_id=>1,
          :cluster_size=>2,
          :domain=>"googletest.com",
          :global_volume=>7637758,
          :is_pending=>false,
          :platform=>"WSA"
        },
        {
          :categories=>[],
          :cluster_id=>2,
          :cluster_size=>2,
          :domain=>"127.0.0.1",
          :global_volume=>7637759,
          :is_pending=>false,
          :platform=>"WSA"
        }
      ]
    end
    context 'when no regex passed' do
      it 'shoud return clusters assigned to user and unassigned' do
        expect(Wbrs::Cluster).to receive(:where)
        expect(subject.fetch).to eq(expected_response)
      end
    end

    context 'when regex passed' do
      let(:regex) { '/some_regex/' }

      it 'shoud return clusters' do
        expect(Wbrs::Cluster).to receive(:where)
        expect(subject.fetch).to eq(expected_response)
      end
    end
  end
end
