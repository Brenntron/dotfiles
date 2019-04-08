describe Dispute do
  describe 'robust_search' do
    before(:all) do
      @current_user = FactoryBot.create(:current_user)
      @default = FactoryBot.create(:file_reputation_dispute)
      @assigned = FactoryBot.create(:file_reputation_dispute, status: FileReputationDispute::STATUS_ASSIGNED)
      @closed = FactoryBot.create(:file_reputation_dispute, status: FileReputationDispute::STATUS_CLOSED)
      @my_default = FactoryBot.create(:file_reputation_dispute, user: @current_user)
      @my_assigned = FactoryBot.create(:file_reputation_dispute, status: FileReputationDispute::STATUS_ASSIGNED, user: @current_user)
      @my_closed = FactoryBot.create(:file_reputation_dispute, status: FileReputationDispute::STATUS_CLOSED, user: @current_user)
    end

    it 'gets all records from a robust_search' do

      results = FileReputationDispute.robust_search(nil, user: @current_user)

      expect(results.count).to eq(6)
    end

    it 'gets my_disputes standard search from a robust_search' do

      results = FileReputationDispute.robust_search('standard', search_name: 'my_disputes', user: @current_user)

      expect(results.count).to eq(3)
    end

    it 'gets closed standard search from a robust_search' do

      results = FileReputationDispute.robust_search('standard', search_name: 'closed', user: @current_user)

      expect(results.count).to eq(2)
    end
  end
end
