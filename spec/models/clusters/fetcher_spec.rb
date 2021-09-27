describe Clusters::Fetcher do
  subject { described_class.new(filter, regex, user) }

  before do
    allow(Clusters::Wbnp::DataFetcher).to receive_message_chain(:new, :fetch).and_return(wbnp_clusters)
    allow(Clusters::Ngfw::DataFetcher).to receive_message_chain(:new, :fetch).and_return(ngfw_clusters)
    allow(Clusters::Filter).to receive_message_chain(:new, :filter).and_return(expected_response)
    allow(Wbrs::TopUrl).to receive(:check_urls).and_return(top_urls)
    allow(Beaker::Verdicts).to receive(:verdicts).and_return(verdicts)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:regex) { nil }

  let(:wbnp_clusters) do
    [
      {
        :cluster_id=>1,
        :domain=>"googletest.com",
        :global_volume=>7637758,
        :cluster_size=>2,
        :is_pending=>false,
        :categories=>[],
        :platform=>"WSA"
      }
    ]
  end

  let(:ngfw_clusters) do
    [
      {
        :cluster_id=>"",
        :cluster_size=>nil,
        :domain=>"127.0.0.1",
        :global_volume=>2821,
        :is_pending=>false,
        :categories=>[],
        :platform=>"NGFW"
      }
    ]
  end

  let(:top_urls) do
    [
      Wbrs::TopUrl.new_from_datum(url: 'googletest.com', is_important: true),
      Wbrs::TopUrl.new_from_datum(url: '127.0.0.1', is_important: true),
    ]
  end

  let(:verdicts) do
    [{"request"=>{"url"=>"googletest.com"}, "response"=>{"thrt"=>{"scor"=>-3.0, "rhts"=>[72], "thrt_vers"=>3}}},
      {"request"=>{"url"=>"127.0.0.1"}, "response"=>{"thrt"=>{"scor"=>-3.0, "rhts"=>[72], "thrt_vers"=>3}}}]
  end

  let(:expected_response) do
    [
      {
        :assigned_to=>"",
        :categories=>[],
        :cluster_id=>1,
        :cluster_size=>2,
        :domain=>"googletest.com",
        :global_volume=>7637758,
        :is_important=>true,
        :is_pending=>false,
        :platform=>"WSA",
        :wbrs_score=>-3.0
      },
      {
        :assigned_to=>"",
        :categories=>[],
        :cluster_id=>'',
        :cluster_size=>nil,
        :domain=>"127.0.0.1",
        :global_volume=>2821,
        :is_important=>true,
        :is_pending=>false,
        :platform=>"NGFW",
        :wbrs_score=>-3.0
      }
    ]
  end

  describe '.fetch' do
    let(:filter) { nil }

    it 'should return all clusters' do
      expect(Clusters::Wbnp::DataFetcher).to receive_message_chain(:new, :fetch)
      expect(Clusters::Ngfw::DataFetcher).to receive_message_chain(:new, :fetch)
      expect(Clusters::Filter).to receive_message_chain(:new, :filter)
      expect(subject.fetch).to eq(expected_response)
    end

    it 'populates assigned_to attribute' do
      expect(subject.fetch.first).to include(:assigned_to)
    end

    it 'populates is_important attribute' do
      expect(subject.fetch.first).to include(:is_important)
    end

    it 'populates wbrs_score attribute' do
      expect(subject.fetch.first).to include(:wbrs_score)
    end

    describe 'platforms filter' do
      context 'WSA filter' do
        let(:filter) { { platform: 'WSA' } }
        let(:expected_response) { wbnp_clusters }
        it 'returns WSA clusters only' do
          expect(subject.fetch).to eq(expected_response)
        end
      end
      context 'NGFW filter' do
        let(:filter) { { platform: 'NGFW' } }
        let(:expected_response) { ngfw_clusters }
        it 'returns NGFW clusters only' do
          expect(subject.fetch).to eq(expected_response)
        end
      end
    end

    describe 'cluster type filter' do
      context 'domain filter' do
        let(:filter) { { cluster_type: 'domain' } }

        let(:expected_response) do
          [
            {
              :assigned_to=>"",
              :categories=>[],
              :cluster_id=>1,
              :cluster_size=>2,
              :domain=>"googletest.com",
              :global_volume=>7637758,
              :is_important=>true,
              :is_pending=>false,
              :platform=>"WSA",
              :wbrs_score=>-3.0
            }
          ]
        end

        it 'returns clusters with domains only' do
          expect(subject.fetch).to eq(expected_response)
        end
      end

      context 'domain filter' do
        let(:filter) { { cluster_type: 'ip' } }

        let(:expected_response) do
          [
            {
              :assigned_to=>"",
              :categories=>[],
              :cluster_id=>'',
              :cluster_size=>nil,
              :domain=>"127.0.0.1",
              :global_volume=>2821,
              :is_important=>true,
              :is_pending=>false,
              :platform=>"NGFW",
              :wbrs_score=>-3.0
            }
          ]
        end

        it 'returns clusters with ip addresses only' do
          expect(subject.fetch).to eq(expected_response)
        end
      end
    end
  end
end
