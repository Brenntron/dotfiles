describe Dispute do
  describe 'robust_search' do
    before(:all) do
      @long_desc1 = 'Long Cool Woman In A Black Dress'
      @long_desc2 = 'Short Skirt Long Jacket'

      @current_user = FactoryBot.create(:current_user)
      @other_user = FactoryBot.create(:fake_user)

      @default = FactoryBot.create(:file_reputation_dispute, assigned: @other_user)
      @assigned = FactoryBot.create(:file_reputation_dispute, status: FileReputationDispute::STATUS_ASSIGNED, assigned: @other_user)
      @closed = FactoryBot.create(:file_reputation_dispute, status: FileReputationDispute::STATUS_RESOLVED, assigned: @other_user, description: @long_desc2)
      @my_default = FactoryBot.create(:file_reputation_dispute, assigned: @current_user, description: @long_desc1)
      @my_assigned = FactoryBot.create(:file_reputation_dispute, status: FileReputationDispute::STATUS_ASSIGNED, assigned: @current_user)
      @my_closed = FactoryBot.create(:file_reputation_dispute, status: FileReputationDispute::STATUS_RESOLVED, assigned: @current_user)
      @unassigned = FactoryBot.create(:file_reputation_dispute, assigned: nil)
    end

    it 'gets all records from a robust_search' do

      results = FileReputationDispute.robust_search(nil, user: @current_user)

      expect(results.count).to eq(7)
    end

    it 'gets contains search from a robust_search' do

      results = FileReputationDispute.robust_search('contains', params: { 'value' => 'Long' }, user: @current_user)

      expect(results.count).to eq(2)
    end

    it 'gets closed standard search from a robust_search' do

      results = FileReputationDispute.robust_search('standard', search_name: 'closed', user: @current_user)

      expect(results.count).to eq(2)
    end

    it 'gets open standard search from a robust_search' do

      results = FileReputationDispute.robust_search('standard', search_name: 'open', user: @current_user)

      expect(results.count).to eq(5)
    end

    it 'gets unassigned standard search from a robust_search' do

      results = FileReputationDispute.robust_search('standard', search_name: 'unassigned', user: @current_user)

      expect(results.count).to eq(1)
    end

    it 'gets my_disputes standard search from a robust_search' do

      results = FileReputationDispute.robust_search('standard', search_name: 'my_disputes', user: @current_user)

      expect(results.count).to eq(3)
    end

    it 'gets my_open standard search from a robust_search' do

      results = FileReputationDispute.robust_search('standard', search_name: 'my_open', user: @current_user)

      expect(results.count).to eq(2)
    end

    it 'gets advanced search from a robust_search' do

      results = FileReputationDispute.robust_search('advanced', params: {'description' => @long_desc2}, user: @current_user)

      expect(results.count).to eq(1)
    end

    it 'saves a named search and gets it from a robust_search' do
      FileReputationDispute.robust_search('advanced',
                                          search_name: 'bad-mess',
                                          params: {'description' => @long_desc1},
                                          user: @current_user)

      results = FileReputationDispute.robust_search('named',
                                                    search_name: 'bad-mess',
                                                    user: @current_user)

      expect(results.count).to eq(1)
    end
  end
end
