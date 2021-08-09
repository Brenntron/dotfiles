describe WebcatCredits::ComplaintEntries::CreditProcessor do
  subject { described_class.new(user, complaint_entry).process }

  before do
    allow(WebcatCredits::ComplaintEntries::CreditHandler).to receive(:new).and_return(
      double(
        handle_pending_credit: true,
        handle_unchanged_credit: true,
        handle_fixed_credit: true,
        handle_invalid_credit: true,
        handle_duplicate_credit: true
      )
    )
  end

  # let(:complaint_entry) { FactoryBot.create(:complaint_entry) }
  let(:user) { FactoryBot.create(:user) }
  let(:credit_handler) { WebcatCredits::ComplaintEntries::CreditHandler.new(user, complaint_entry) }

  context 'when complaint entry is PENDING' do
    let(:complaint_entry) { FactoryBot.create(:complaint_entry, status: 'PENDING') }

    it 'calls PENDING credit processing' do
      expect(credit_handler).to receive(:handle_pending_credit)
      subject
    end
  end

  context 'when complaint entry is ASSIGNED' do
    let(:complaint_entry) { FactoryBot.create(:complaint_entry, status: 'ASSIGNED') }

    it 'calls UNCHANGED credit processing' do
      expect(credit_handler).to receive(:handle_unchanged_credit)
      subject
    end
  end

  context 'when complain entry is COMPLETED' do
    context 'when complaint entry has fixed resolution' do
      let(:complaint_entry) { FactoryBot.create(:complaint_entry, status: 'COMPLETED', resolution: 'FIXED') }

      it 'calls FIXED credit processing' do
        expect(credit_handler).to receive(:handle_fixed_credit)
        subject
      end
    end

    context 'when complaint entry has unchanged resolution' do
      let(:complaint_entry) { FactoryBot.create(:complaint_entry, status: 'COMPLETED', resolution: 'UNCHANGED') }

      it 'calls UNCHANGED credit processing' do
        expect(credit_handler).to receive(:handle_unchanged_credit)
        subject
      end
    end

    context 'when complaint entry has invalid resolution' do
      let(:complaint_entry) { FactoryBot.create(:complaint_entry, status: 'COMPLETED', resolution: 'INVALID') }

      it 'calls INVALID credit processing' do
        expect(credit_handler).to receive(:handle_invalid_credit)
        subject
      end
    end

    context 'when complaint entry has duplicate resolution' do
      let(:complaint_entry) { FactoryBot.create(:complaint_entry, status: 'COMPLETED', resolution: 'DUPLICATE') }

      it 'calls DUPLICATE credit processing' do
        expect(credit_handler).to receive(:handle_duplicate_credit)
        subject
      end
    end

    context 'when complaint entry has a blank resolution' do
      let(:complaint_entry) { FactoryBot.create(:complaint_entry, status: 'COMPLETED', resolution: '') }

      it 'calls FIXED credit processing' do
        expect(credit_handler).to receive(:handle_fixed_credit)
        subject
      end
    end
  end
end
