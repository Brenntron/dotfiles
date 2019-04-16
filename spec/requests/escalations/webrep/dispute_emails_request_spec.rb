require "rails_helper"

# post url, params: {}, headers: {}, env: {}, xhr: false, as: :symbol

RSpec.describe API::V1::Escalations::Webrep::DisputeEmails, type: :request do
  before(:all) do
    @current_user = FactoryBot.create(:current_user)
    @current_user.roles << FactoryBot.create(:file_rep_role)
    @username = @current_user.cvs_username
    @auth_token = @current_user.authentication_token
  end

  context 'one existing file rep disputes' do
    before(:all) do
      @fr_dispute = FactoryBot.create(:file_reputation_dispute)
      @fr_dispute_id = @fr_dispute.id
    end

    it 'receives outgoing email AJAX call' do
      to = 'george@microsoft.com'
      from = "#{@username}@cisco.com"
      subject = "Hey wait a minute"
      body = "Are you trolling me?"

      post '/escalations/api/v1/escalations/webrep/dispute_emails', as: :json, headers: { 'Token' => @auth_token },
           params: { dispute_id: @fr_dispute_id, dispute_type: 'FileReputationDispute',
                     to: to, from: from, subject: subject, body: body }

      puts response.code
      puts response.body
      byebug
    end
  end
end
