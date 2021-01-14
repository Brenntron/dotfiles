describe ComplaintEntryCredits::CreditHandler do
  let(:complaint_entry) { FactoryBot.create(:complaint_entry) }
  let(:user) { FactoryBot.create(:user) }

  describe 'PENDING credit' do
    subject { described_class.handle_pending_credit(user, complaint_entry) }

    context 'when user does not have credits for the complaint entry' do
      it 'adds PENDING credit for the user' do
        expect { subject }.to change { ComplaintEntryCredit }.to(1)
        expect(user.complaint_entry_credits).to be 1
        expect(user.complaint_entry_credits.last.credit).to eq ComplaintEntryCredit::PENDING
      end
    end

    context 'when user has any other credit for the complaint entry' do
      before do
        ComplaintEntryCredit.create(
          user_id: user.id,
          complaint_entry_id: complaint_entry.id,
          credit: ComplaintEntryCredit::UNCHANGED
        )
      end

      it 'removes prevoius credit and adds the PENDING credit' do
        subject
        expect(user.complaint_entry_credits).to be 1
        expect(user.complaint_entry_credits.last.credit).to eq ComplaintEntryCredit::PENDING
      end
    end
  end

  describe 'UNCHANGED credit' do
    subject { described_class.handle_unchanged_credit(user, complaint_entry) }

    context 'when user does not have credits for the complaint entry' do
      it 'adds UNCHANGED credit for the user' do
        expect { subject }.to change { ComplaintEntryCredit }.to(1)
        expect(user.complaint_entry_credits).to be 1
        expect(user.complaint_entry_credits.last.credit).to eq ComplaintEntryCredit::UNCHANGED
      end
    end

    context 'when user has any other credit for the complaint entry' do
      before do
        ComplaintEntryCredit.create(
          user_id: user.id,
          complaint_entry_id: complaint_entry.id,
          credit: ComplaintEntryCredit::PENDING
        )
      end

      it 'removes prevoius credit and adds the PENDING credit' do
        subject
        expect(user.complaint_entry_credits).to be 1
        expect(user.complaint_entry_credits.last.credit).to eq ComplaintEntryCredit::UNCHANGED
      end
    end
  end

  describe 'FIXED credit' do
    subject { described_class.handle_fixed_credit(user, complaint_entry) }

    context 'when user does not have credits for the complaint entry' do
      it 'adds FIXED credit for the user' do
        expect { subject }.to change { ComplaintEntryCredit }.to(1)
        expect(user.complaint_entry_credits).to be 1
        expect(user.complaint_entry_credits.last.credit).to eq ComplaintEntryCredit::FIXED
      end
    end

    context 'when user has any other credit for the complaint entry' do
      before do
        ComplaintEntryCredit.create(
          user_id: user.id,
          complaint_entry_id: complaint_entry.id,
          credit: ComplaintEntryCredit::PENDING
        )
      end

      it 'removes prevoius credit and adds the PENDING credit' do
        subject
        expect(user.complaint_entry_credits).to be 1
        expect(user.complaint_entry_credits.last.credit).to eq ComplaintEntryCredit::FIXED
      end
    end
  end

  describe 'INVALID credit' do
    subject { described_class.handle_invalid_credit(user, complaint_entry) }

    context 'when user does not have credits for the complaint entry' do
      it 'adds INVALID credit for the user' do
        expect { subject }.to change { ComplaintEntryCredit }.to(1)
        expect(user.complaint_entry_credits).to be 1
        expect(user.complaint_entry_credits.last.credit).to eq ComplaintEntryCredit::INVALID
      end
    end

    context 'when user has any other credit for the complaint entry' do
      before do
        ComplaintEntryCredit.create(
          user_id: user.id,
          complaint_entry_id: complaint_entry.id,
          credit: ComplaintEntryCredit::PENDING
        )
      end

      it 'removes prevoius credit and adds the PENDING credit' do
        subject
        expect(user.complaint_entry_credits).to be 1
        expect(user.complaint_entry_credits.last.credit).to eq ComplaintEntryCredit::INVALID
      end
    end
  end

  describe 'DUPLICATED credit' do
    subject { described_class.handle_duplicated_credit(user, complaint_entry) }

    context 'when user does not have credits for the complaint entry' do
      it 'adds DUPLICATED credit for the user' do
        expect { subject }.to change { ComplaintEntryCredit }.to(1)
        expect(user.complaint_entry_credits).to be 1
        expect(user.complaint_entry_credits.last.credit).to eq ComplaintEntryCredit::DUPLICATED
      end
    end

    context 'when user has any other credit for the complaint entry' do
      before do
        ComplaintEntryCredit.create(
          user_id: user.id,
          complaint_entry_id: complaint_entry.id,
          credit: ComplaintEntryCredit::PENDING
        )
      end

      it 'removes prevoius credit and adds the DUPLICATED credit' do
        subject
        expect(user.complaint_entry_credits).to be 1
        expect(user.complaint_entry_credits.last.credit).to eq ComplaintEntryCredit::DUPLICATED
      end
    end
  end
end
