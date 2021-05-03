describe Clusters::Wbnp::DataFetcher do
  subject { described_class.new(regex) }

  before do
    allow(Wbrs::Cluster).to receive(:all).and_return(clusters)
    allow(Wbrs::Cluster).to receive(:where).and_return(clusters)
    allow(Wbrs::TopUrl).to receive(:check_urls).and_return(top_urls)
    allow(Beaker::Verdicts).to receive(:verdicts).and_return(verdicts)

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

  let(:top_urls) do
    [
      Wbrs::TopUrl.new_from_datum(url: 'googletest.com', is_important: true),
      Wbrs::TopUrl.new_from_datum(url: '127.0.0.1', is_important: true),
      Wbrs::TopUrl.new_from_datum(url: 'googletest2.com', is_important: true)
    ]
  end

  let(:verdicts) do
    [{"request"=>{"url"=>"googletest.com"}, "response"=>{"thrt"=>{"scor"=>-3.0, "rhts"=>[72], "thrt_vers"=>3}}},
      {"request"=>{"url"=>"googletest2.com"}, "response"=>{"thrt"=>{"scor"=>-3.0, "rhts"=>[72], "thrt_vers"=>3}}}]
  end

  let(:regex) { nil }

  describe '.fetch' do
    let(:expected_response) do
      [
        {
          :age=>"3 months, 1 week, 3 days, 11 hours, and 6 minutes",
          :assigned_to=>"",
          :categories=>[],
          :cluster_id=>1,
          :cluster_size=>2,
          :ctime=>"Fri, 21 Sep 2018 12:53:40 GMT",
          :domain=>"googletest.com",
          :global_volume=>7637758,
          :is_important=>true,
          :is_pending=>false,
          :platform=>"WSA"
        },
        {
          :age=>"3 months, 1 week, 2 days, 11 hours, and 6 minutes",
          :assigned_to=>"",
          :categories=>[],
          :cluster_id=>2,
          :cluster_size=>2,
          :ctime=>"Sat, 22 Sep 2018 12:53:40 GMT",
          :domain=>"127.0.0.1",
          :global_volume=>7637759,
          :is_important=>true,
          :is_pending=>false,
          :platform=>"WSA"
        }
      ]
    end
    context 'when no regex passed' do
      it 'shoud return clusters assigned to user and unassigned' do
        expect(Wbrs::Cluster).to receive(:all)
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

    describe 'assignments' do
      context 'when cluster is assigned' do
        before { FactoryBot.create(:cluster_assignment, user_id: user.id, cluster_id: 1) }

        let(:user) { FactoryBot.create(:user) }
        let(:expected_response) do
          [
            {
              :age=>"3 months, 1 week, 3 days, 11 hours, and 6 minutes",
              :assigned_to=>user.cvs_username,
              :categories=>[],
              :cluster_id=>1,
              :cluster_size=>2,
              :ctime=>"Fri, 21 Sep 2018 12:53:40 GMT",
              :domain=>"googletest.com",
              :global_volume=>7637758,
              :is_important=>true,
              :is_pending=>false,
              :platform=>"WSA"
            },
            {
              :age=>"3 months, 1 week, 2 days, 11 hours, and 6 minutes",
              :assigned_to=>"",
              :categories=>[],
              :cluster_id=>2,
              :cluster_size=>2,
              :ctime=>"Sat, 22 Sep 2018 12:53:40 GMT",
              :domain=>"127.0.0.1",
              :global_volume=>7637759,
              :is_important=>true,
              :is_pending=>false,
              :platform=>"WSA"
            }
          ]
        end

        it 'returns assigned_to as user cvs_username' do
          expect(subject.fetch).to eq(expected_response)
        end
      end
    end
  end
end
