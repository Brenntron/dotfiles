describe ComplaintEntryCredits::CreditProcessor do
  subject { described_class.process(user, complaint_entry, status) }

  let(:complaint_entry) { FactoryBot.create(:complaint_entry) }
  let(:user) { FactoryBot.create(:user) }

  context 'when complaint entry is going to have fixed resolution' do
    let(:status) { 'fixed' }
    before do
      allow(ComplaintEntryCredits::CreditHandler).to receive(:handle_pending_credit).and_return(true)
    end

    it 'calls PENDING credit processing' do
      expect(ComplaintEntryCredits::CreditHandler).to receive(:handle_pending_credit)
      subject
    end
  end

  context 'when complaint entry is going to have unchanged resolution' do
    let(:status) { 'unchanged' }
    before do
      allow(ComplaintEntryCredits::CreditHandler).to receive(:handle_unchanged_credit).and_return(true)
    end

    it 'calls UNCHANGED credit processing' do
      expect(ComplaintEntryCredits::CreditHandler).to receive(:handle_unchanged_credit)
      subject
    end
  end

  context 'when complaint entry is going to have commit resolution' do
    let(:status) { 'commit' }
    before do
      allow(ComplaintEntryCredits::CreditHandler).to receive(:handle_fixed_credit).and_return(true)
    end

    it 'calls FIXED credit processing' do
      expect(ComplaintEntryCredits::CreditHandler).to receive(:handle_fixed_credit)
      subject
    end
  end

  context 'when complaint entry is going to have decline resolution' do
    let(:status) { 'decline' }
    before do
      allow(ComplaintEntryCredits::CreditHandler).to receive(:handle_unchanged_credit).and_return(true)
    end

    it 'calls UNCHANGED credit processing' do
      expect(ComplaintEntryCredits::CreditHandler).to receive(:handle_unchanged_credit)
      subject
    end
  end

  context 'when complaint entry is going to have invalid resolution' do
    let(:status) { 'invalid' }
    before do
      allow(ComplaintEntryCredits::CreditHandler).to receive(:handle_invalid_credit).and_return(true)
    end

    it 'calls INVALID credit processing' do
      expect(ComplaintEntryCredits::CreditHandler).to receive(:handle_invalid_credit)
      subject
    end
  end

  context 'when complaint entry is going to have duplicate resolution' do
    let(:status) { 'duplicate' }
    before do
      allow(ComplaintEntryCredits::CreditHandler).to receive(:handle_duplicate_credit).and_return(true)
    end

    it 'calls INVALID credit processing' do
      expect(ComplaintEntryCredits::CreditHandler).to receive(:handle_duplicate_credit)
      subject
    end
  end
end
