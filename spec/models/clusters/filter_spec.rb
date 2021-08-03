describe Clusters::Filter do
  subject { described_class.new(clusters, filter, user) }

  let(:user) { FactoryBot.create(:user) }
  let(:clusters) do
    [
      {
        :assigned_to=>user.cvs_username,
        :categories=>[],
        :cluster_id=>'',
        :cluster_size=>nil,
        :domain=>"example.com",
        :global_volume=>2821,
        :is_important=>true,
        :is_pending=>false,
        :platform=>"NGFW",
        :wbrs_score=>-3.0
      },
      {
        :assigned_to=>"",
        :categories=>[],
        :cluster_id=>1,
        :cluster_size=>2,
        :domain=>"googletest.com",
        :global_volume=>7637758,
        :is_important=>false,
        :is_pending=>true,
        :platform=>"WSA",
        :wbrs_score=>-3.0
      }
    ]
  end



  describe 'user specific filters' do
    describe 'all filter' do
      let(:filter) { { f: 'all' } }

      let(:expected_response) { clusters }

      it 'shoud return all clusters' do
        expect(subject.filter).to eq(expected_response)
      end
    end

    describe 'my filter' do
      let(:filter) { { f: 'my' } }

      let(:expected_response) do
        [
          {
            :assigned_to=>user.cvs_username,
            :categories=>[],
            :cluster_id=>'',
            :cluster_size=>nil,
            :domain=>"example.com",
            :global_volume=>2821,
            :is_important=>true,
            :is_pending=>false,
            :platform=>"NGFW",
            :wbrs_score=>-3.0
          }
        ]
      end

      it 'returns only assigned cluster' do
        expect(subject.filter).to eq(expected_response)
      end
    end

    describe 'unassigned filter' do
      let(:filter) { { f: 'unassigned' } }

      let(:expected_response) do
        [
          {
            :assigned_to=>"",
            :categories=>[],
            :cluster_id=>1,
            :cluster_size=>2,
            :domain=>"googletest.com",
            :global_volume=>7637758,
            :is_important=>false,
            :is_pending=>true,
            :platform=>"WSA",
            :wbrs_score=>-3.0
          }
        ]
      end

      it 'returns only unassigned clusters' do
        expect(subject.filter).to eq(expected_response)
      end
    end

    describe 'pending filter' do
      let(:filter) { { f: 'pending' } }

      let(:expected_response) do
        [
          {
            :assigned_to=>"",
            :categories=>[],
            :cluster_id=>1,
            :cluster_size=>2,
            :domain=>"googletest.com",
            :global_volume=>7637758,
            :is_important=>false,
            :is_pending=>true,
            :platform=>"WSA",
            :wbrs_score=>-3.0
          }
        ]
      end

      it 'returns only pending clusters' do
        expect(subject.filter).to eq(expected_response)
      end
    end
  end
end
