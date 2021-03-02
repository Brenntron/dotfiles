describe Webcat::ClustersFetcher do
  subject { described_class.new(filter, regex, user) }

  before { Timecop.freeze(Time.local(2019)) }  # freeze time to test time-related fields
  after { Timecop.unfreeze }

  describe '.fetch' do
    before do
      allow(Wbrs::Cluster).to receive(:all).and_return(clusters)
      allow(Wbrs::Cluster).to receive(:where).and_return(clusters)
      allow(Beaker::Verdicts).to receive(:verdicts).and_return(verdicts)
    end

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
            'domain'=>"googletest1.com",
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

    let(:verdicts) do
      [{"request"=>{"url"=>"googletest.com"}, "response"=>{"thrt"=>{"scor"=>-3.0, "rhts"=>[72], "thrt_vers"=>3}}},
        {"request"=>{"url"=>"googletest2.com"}, "response"=>{"thrt"=>{"scor"=>-3.0, "rhts"=>[72], "thrt_vers"=>3}}}]
    end

    let(:filter) { nil }
    let(:regex) { nil }
    let(:user) { nil }

    context 'when no filter and regex passed' do
      let(:user) { FactoryBot.create(:user) }
      let(:another_user) { FactoryBot.create(:user) }

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
              'domain'=>"googletest1.com",
              'ctime'=>"Sat, 22 Sep 2018 12:53:40 GMT",
              'mtime'=>"Sat, 22 Sep 2018 12:53:40 GMT",
              'apac_volume'=>0,
              'emrg_volume'=>0,
              'eurp_volume'=>0,
              'japn_volume'=>0,
              'glob_volume'=>7637759,
              'cluster_size'=>2
            },
            {
              'cluster_id'=>3,
              'domain'=>"googletest2.com",
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

      let(:expected_response) do
        {
          meta: {"limit"=>1000, "rows_found"=>15161},
          data: [
            {
              :cluster_id=>1,
              :domain=>"googletest.com",
              :global_volume=>7637758,
              :ctime=>"Fri, 21 Sep 2018 12:53:40 GMT",
              :cluster_size=>2,
              :age=>"3 months, 1 week, 3 days, 9 hours, and 6 minutes",
              :wbrs_score=>-3.0,
              :assigned_to=>"user1"
            },
            {
              :cluster_id=>3,
              :domain=>"googletest2.com",
              :global_volume=>7637759,
              :ctime=>"Sat, 22 Sep 2018 12:53:40 GMT",
              :cluster_size=>2,
              :age=>"3 months, 1 week, 2 days, 9 hours, and 6 minutes",
              :wbrs_score=>-3.0,
              :assigned_to=>""
            }
          ]
        }
      end

      before do
        FactoryBot.create(:cluster_assignment, user_id: user.id, cluster_id: 1)
        FactoryBot.create(:cluster_assignment, user_id: another_user.id, cluster_id: 2)
      end

      it 'shoud return clusters assigned to user and unassigned' do
        expect(Wbrs::Cluster).to receive(:all)
        expect(subject.fetch).to eq(expected_response)
      end
    end

    context 'when regex passed' do
      let(:clusters) do
        {
          'meta'=>{"limit"=>1000, "rows_found"=>15161},
          'data'=> [
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
            }
          ]
        }
      end

      let(:regex) { '/some_regex/' }
      let(:expected_response) do
        {
          meta: {"limit"=>1000, "rows_found"=>15161},
          data: [
            {
              :cluster_id=>1,
              :domain=>"googletest.com",
              :global_volume=>7637758,
              :ctime=>"Fri, 21 Sep 2018 12:53:40 GMT",
              :cluster_size=>2,
              :age=>"3 months, 1 week, 3 days, 9 hours, and 6 minutes",
              :wbrs_score=>-3.0,
              :assigned_to=>""
            }
          ]
        }
      end

      it 'shoud return clusters' do
        expect(Wbrs::Cluster).to receive(:where)
        expect(subject.fetch).to eq(expected_response)
      end
    end

    describe 'filters' do
      describe 'all filter' do
        let(:filter) { 'all' }
        let(:expected_response) do
          {
            meta: {"limit"=>1000, "rows_found"=>15161},
            data: [
              {
                :cluster_id=>1,
                :domain=>"googletest.com",
                :global_volume=>7637758,
                :ctime=>"Fri, 21 Sep 2018 12:53:40 GMT",
                :cluster_size=>2,
                :age=>"3 months, 1 week, 3 days, 9 hours, and 6 minutes",
                :wbrs_score=>-3.0,
                :assigned_to=>""
              },
              {
                :cluster_id=>2,
                :domain=>"googletest1.com",
                :global_volume=>7637759,
                :ctime=>"Sat, 22 Sep 2018 12:53:40 GMT",
                :cluster_size=>2,
                :age=>"3 months, 1 week, 2 days, 9 hours, and 6 minutes",
                :wbrs_score=>-3.0,
                :assigned_to=>""
              }
            ]
          }
        end

        it 'shoud return all clusters' do
          expect(subject.fetch).to eq(expected_response)
        end
      end
      describe 'my filter' do
        before { FactoryBot.create(:cluster_assignment, user_id: user.id, cluster_id: 1) }

        let(:filter) { 'my' }
        let(:user) { FactoryBot.create(:user) }
        let(:expected_response) do
          {
            meta: {"limit"=>1000, "rows_found"=>15161},
            data: [
              {
                :cluster_id=>1,
                :domain=>"googletest.com",
                :global_volume=>7637758,
                :ctime=>"Fri, 21 Sep 2018 12:53:40 GMT",
                :cluster_size=>2,
                :age=>"3 months, 1 week, 3 days, 9 hours, and 6 minutes",
                :wbrs_score=>-3.0,
                :assigned_to=>user.cvs_username
              }
            ]
          }
        end

        it 'returns only assigned cluster' do
          expect(subject.fetch).to eq(expected_response)
        end
      end

      describe 'unassigned filter' do
        before { FactoryBot.create(:cluster_assignment, user_id: user.id, cluster_id: 1) }

        let(:filter) { 'unassigned' }
        let(:user) { FactoryBot.create(:user) }
        let(:expected_response) do
          {
            meta: {"limit"=>1000, "rows_found"=>15161},
            data: [
              {
                :cluster_id=>2,
                :domain=>"googletest1.com",
                :global_volume=>7637759,
                :ctime=>"Sat, 22 Sep 2018 12:53:40 GMT",
                :cluster_size=>2,
                :age=>"3 months, 1 week, 2 days, 9 hours, and 6 minutes",
                :wbrs_score=>-3.0,
                :assigned_to=>""
              }
            ]
          }
        end

        it 'returns only unassigned clusters' do
          expect(subject.fetch).to eq(expected_response)
        end
      end
    end

    describe 'assignments' do
      context 'when cluster is assigned' do
        before { FactoryBot.create(:cluster_assignment, user_id: user.id, cluster_id: 1) }

        let(:filter) { 'my' }
        let(:user) { FactoryBot.create(:user) }
        let(:expected_response) do
          {
            meta: {"limit"=>1000, "rows_found"=>15161},
            data: [
              {
                :cluster_id=>1,
                :domain=>"googletest.com",
                :global_volume=>7637758,
                :ctime=>"Fri, 21 Sep 2018 12:53:40 GMT",
                :cluster_size=>2,
                :age=>"3 months, 1 week, 3 days, 9 hours, and 6 minutes",
                :wbrs_score=>-3.0,
                :assigned_to=>user.cvs_username
              }
            ]
          }
        end

        it 'returns assigned_to as user cvs_username' do
          expect(subject.fetch).to eq(expected_response)
        end
      end

      context 'when cluster is not assigned' do
        let(:expected_response) do
          {
            meta: {"limit"=>1000, "rows_found"=>15161},
            data: [
              {
                :cluster_id=>1,
                :domain=>"googletest.com",
                :global_volume=>7637758,
                :ctime=>"Fri, 21 Sep 2018 12:53:40 GMT",
                :cluster_size=>2,
                :age=>"3 months, 1 week, 3 days, 9 hours, and 6 minutes",
                :wbrs_score=>-3.0,
                :assigned_to=>""
              },
              {
                :cluster_id=>2,
                :domain=>"googletest1.com",
                :global_volume=>7637759,
                :ctime=>"Sat, 22 Sep 2018 12:53:40 GMT",
                :cluster_size=>2,
                :age=>"3 months, 1 week, 2 days, 9 hours, and 6 minutes",
                :wbrs_score=>-3.0,
                :assigned_to=>""
              }
            ]
          }
        end

        it 'returns empty assigned_to' do
          expect(subject.fetch).to eq(expected_response)
        end
      end
    end
  end
end
