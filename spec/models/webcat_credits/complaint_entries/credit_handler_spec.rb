describe WebcatCredits::ComplaintEntries::CreditHandler do
  subject(:handler) { described_class.new(user, complaint_entry) }
  let(:complaint_entry) { FactoryBot.create(:complaint_entry) }
  let(:user) { FactoryBot.create(:user) }

  describe 'PENDING credit' do
    subject { handler.handle_pending_credit }

    context 'when user does not have credits for the complaint entry' do
      it 'adds PENDING credit for the user' do
        expect { subject }.to change { ComplaintEntryCredit.count }.to(1)
        expect(user.webcat_credits.count).to be 1
        expect(user.webcat_credits.last.credit).to eq WebcatCredit::PENDING
      end
    end

    context 'when user has any other credit for the complaint entry' do
      before do
        ComplaintEntryCredit.create(
          user_id: user.id,
          complaint_entry_id: complaint_entry.id,
          credit: WebcatCredit::UNCHANGED
        )
      end

      it 'removes prevoius credit and adds the PENDING credit' do
        subject
        expect(user.webcat_credits.count).to be 1
        expect(user.webcat_credits.last.credit).to eq WebcatCredit::PENDING
      end
    end
  end

  describe 'UNCHANGED credit' do
    subject { handler.handle_unchanged_credit }

    context 'when user does not have credits for the complaint entry' do
      it 'adds UNCHANGED credit for the user' do
        expect { subject }.to change { ComplaintEntryCredit.count }.to(1)
        expect(user.webcat_credits.count).to be 1
        expect(user.webcat_credits.last.credit).to eq WebcatCredit::UNCHANGED
      end
    end

    context 'when user has any other credit for the complaint entry' do
      before do
        ComplaintEntryCredit.create(
          user_id: user.id,
          complaint_entry_id: complaint_entry.id,
          credit: WebcatCredit::PENDING
        )
      end

      it 'removes prevoius credit and adds the PENDING credit' do
        subject
        expect(user.webcat_credits.count).to be 1
        expect(user.webcat_credits.last.credit).to eq WebcatCredit::UNCHANGED
      end
    end
  end

  describe 'FIXED credit' do
    subject { handler.handle_fixed_credit }

    context 'when user does not have credits for the complaint entry' do
      it 'adds FIXED credit for the user' do
        expect { subject }.to change { ComplaintEntryCredit.count }.to(1)
        expect(user.webcat_credits.count).to be 1
        expect(user.webcat_credits.last.credit).to eq WebcatCredit::FIXED
      end
    end

    context 'when user has any other credit for the complaint entry' do
      before do
        ComplaintEntryCredit.create(
          user_id: user.id,
          complaint_entry_id: complaint_entry.id,
          credit: WebcatCredit::PENDING
        )
      end

      it 'removes prevoius credit and adds the PENDING credit' do
        subject
        expect(user.webcat_credits.count).to be 1
        expect(user.webcat_credits.last.credit).to eq WebcatCredit::FIXED
      end
    end
  end

  describe 'INVALID credit' do
    subject { handler.handle_invalid_credit }

    context 'when user does not have credits for the complaint entry' do
      it 'adds INVALID credit for the user' do
        expect { subject }.to change { ComplaintEntryCredit.count }.to(1)
        expect(user.webcat_credits.count).to be 1
        expect(user.webcat_credits.last.credit).to eq WebcatCredit::INVALID
      end
    end

    context 'when user has any other credit for the complaint entry' do
      before do
        ComplaintEntryCredit.create(
          user_id: user.id,
          complaint_entry_id: complaint_entry.id,
          credit: WebcatCredit::PENDING
        )
      end

      it 'removes prevoius credit and adds the PENDING credit' do
        subject
        expect(user.webcat_credits.count).to be 1
        expect(user.webcat_credits.last.credit).to eq WebcatCredit::INVALID
      end
    end
  end

  describe 'DUPLICATE credit' do
    subject { handler.handle_duplicate_credit }

    context 'when user does not have credits for the complaint entry' do
      it 'adds DUPLICATE credit for the user' do
        expect { subject }.to change { ComplaintEntryCredit.count }.to(1)
        expect(user.webcat_credits.count).to be 1
        expect(user.webcat_credits.last.credit).to eq WebcatCredit::DUPLICATE
      end
    end

    context 'when user has any other credit for the complaint entry' do
      before do
        ComplaintEntryCredit.create(
          user_id: user.id,
          complaint_entry_id: complaint_entry.id,
          credit: WebcatCredit::PENDING
        )
      end

      it 'removes prevoius credit and adds the DUPLICATE credit' do
        subject
        expect(user.webcat_credits.count).to be 1
        expect(user.webcat_credits.last.credit).to eq WebcatCredit::DUPLICATE
      end
    end
  end
end
