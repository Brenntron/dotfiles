describe WebcatCredits::InternalCategorizations::CreditHandler do
  subject(:handler) { described_class.new(user, domain) }
  let(:domain) { 'example.com' }
  let(:user) { FactoryBot.create(:user) }

  describe 'INTERNAL credit' do
    subject { handler.handle_internal_credit }

    context 'when user does not have credits for the domain' do
      it 'adds INTERNAL credit for the user' do
        expect { subject }.to change { InternalCategorizationCredit.count }.to(1)
        expect(user.webcat_credits.count).to be 1
        expect(user.webcat_credits.last.credit).to eq WebcatCredit::INTERNAL
      end
    end

    context 'when user has any other credit for the domain' do
      before do
        InternalCategorizationCredit.create(
          user_id: user.id,
          domain: domain,
          credit: WebcatCredit::UNCHANGED
        )
      end

      it 'removes previous credit and adds the INTERNAL credit' do
        subject
        expect(user.webcat_credits.count).to be 1
        expect(user.webcat_credits.last.credit).to eq WebcatCredit::INTERNAL
      end
    end
  end
end
