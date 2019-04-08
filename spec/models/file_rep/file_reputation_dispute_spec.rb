describe Dispute do
  describe 'robust_search' do
    before(:all) do
      @current_user = FactoryBot.create(:current_user)
      @default = FactoryBot.create(:file_reputation_dispute)
      @assigned = FactoryBot.create(:file_reputation_dispute, status: FileReputationDispute::STATUS_ASSIGNED)
      @closed = FactoryBot.create(:file_reputation_dispute, status: FileReputationDispute::STATUS_CLOSED)
    end

    it 'gets all records from a robust_search' do

      results = FileReputationDispute.robust_search(nil, user: @current_user)

      expect(results.count).to eq(3)
    end
  end
end
