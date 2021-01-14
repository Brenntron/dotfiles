describe ComplaintEntryCredits::CreditProcessor do
  subject { described_class.new(user, complaint_entry, status).process }

  before do
    allow(ComplaintEntryCredits::CreditHandler).to receive(:new).and_return(
      double(
        handle_pending_credit: true,
        handle_unchanged_credit: true,
        handle_fixed_credit: true,
        handle_invalid_credit: true,
        handle_duplicate_credit: true
      )
    )
  end

  let(:complaint_entry) { FactoryBot.create(:complaint_entry) }
  let(:user) { FactoryBot.create(:user) }
  let(:credit_handler) { ComplaintEntryCredits::CreditHandler.new(user, complaint_entry) }

  context 'when complaint entry is going to have fixed resolution' do
    let(:status) { 'fixed' }

    it 'calls PENDING credit processing' do
      expect(credit_handler).to receive(:handle_pending_credit)
      subject
    end
  end

  context 'when complaint entry is going to have unchanged resolution' do
    let(:status) { 'unchanged' }

    it 'calls UNCHANGED credit processing' do
      expect(credit_handler).to receive(:handle_unchanged_credit)
      subject
    end
  end

  context 'when complaint entry is going to have commit resolution' do
    let(:status) { 'commit' }

    it 'calls FIXED credit processing' do
      expect(credit_handler).to receive(:handle_fixed_credit)
      subject
    end
  end

  context 'when complaint entry is going to have decline resolution' do
    let(:status) { 'decline' }

    it 'calls UNCHANGED credit processing' do
      expect(credit_handler).to receive(:handle_unchanged_credit)
      subject
    end
  end

  context 'when complaint entry is going to have invalid resolution' do
    let(:status) { 'invalid' }

    it 'calls INVALID credit processing' do
      expect(credit_handler).to receive(:handle_invalid_credit)
      subject
    end
  end

  context 'when complaint entry is going to have duplicate resolution' do
    let(:status) { 'duplicate' }

    it 'calls INVALID credit processing' do
      expect(credit_handler).to receive(:handle_duplicate_credit)
      subject
    end
  end
end
