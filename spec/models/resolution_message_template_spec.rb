describe ResolutionMessageTemplate do
  let!(:message) { FactoryBot.create(:resolution_message_template, status: :in_progress) }

  describe 'validations' do
    describe 'body' do
      it 'allow to save empty body for resolved message templates' do
        message.status = :resolved
        message.body = nil
        expect(message).to be_valid
      end

      it 'does not allow  save empty body for in_progress message templates' do
        message.status = :in_progress
        message.body = nil
        expect(message).not_to be_valid
      end
    end

    describe 'name and description immutability for resolved messages' do
      let(:expected_error) { "You can't change name or description for 'Resolved / Closed' messages" }
   
      before do
        message.update(status: :resolved)
      end

      it 'can not change name and description for resolved messages' do
        message.name = 'blabala'
        message.valid?
        expect(message.valid?).to be false
        expect(message.errors[:base]).to include(expected_error)
      end
    end
  end
end
