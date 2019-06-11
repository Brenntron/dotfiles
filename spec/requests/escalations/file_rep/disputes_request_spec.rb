require "rails_helper"

# post url, params: {}, headers: {}, env: {}, xhr: false, as: :symbol

RSpec.describe API::V1::Escalations::FileRep::Disputes, type: :request do
  let(:creater_session) do
    bug_proxy = BugzillaRest::BugProxy.new({id: 101101}, api_key: nil, token: nil)
    double('BugzillaRest::Session', create_bug: bug_proxy)
  end

  before(:all) do
    @current_user = FactoryBot.create(:current_user)
    @current_user.roles << FactoryBot.create(:file_rep_role)
    @username = @current_user.cvs_username
    @auth_token = @current_user.authentication_token
  end

  context 'creating from the AC form' do
    let(:file_rep_noscore) do
      FileReputationDispute.new.tap do |file_rep_noscore|
        allow(file_rep_noscore).to receive(:update_scores)
        allow(file_rep_noscore).to receive(:populate_fields_from_rl)
      end
    end

    before(:all) do
      FactoryBot.create(:customer, name: 'Dispute Analyst')
    end

    it 'can create a file rep dispute via the form' do
      allow(BugzillaRest::Session).to receive(:new).and_return(creater_session)
      allow(FileReputationDispute).to receive(:new).and_return(file_rep_noscore)
      create_form_params = {
          shas_array: %w[
            da8aa2429715ea57c142186130706315c8fc10b1b1fb2d416e63a2ed2734e104
            da926993a4d7a10fc5d7dc1ddf53ba3cb65363cf4bf443e4054c0183bd688ded
          ],
          disposition_suggested: FileReputationDispute::DISPOSITION_MALICIOUS,
          assignee: @current_user.cvs_username
      }

      expect do
        post '/escalations/api/v1/escalations/file_rep/disputes/form', as: :json, headers: { 'Token' => @auth_token },
             params: create_form_params
      end.to change { FileReputationDispute.count }.by(1)

      expect(response).to be_successful
    end

    it 'rejects SHAs which are not hex' do
      allow(BugzillaRest::Session).to receive(:new).and_return(creater_session)
      allow(FileReputationDispute).to receive(:new).and_return(file_rep_noscore)
      create_form_params = {
          shas_array: %w[
            ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/
          ],
          disposition_suggested: FileReputationDispute::DISPOSITION_MALICIOUS,
          assignee: @current_user.cvs_username
      }

      expect do
        post '/escalations/api/v1/escalations/file_rep/disputes/form', as: :json, headers: { 'Token' => @auth_token },
             params: create_form_params
      end.to change { FileReputationDispute.count }.by(0)

      expect(response).to_not be_successful
    end

    it 'rejects SHAs which are too short' do
      allow(BugzillaRest::Session).to receive(:new).and_return(creater_session)
      allow(FileReputationDispute).to receive(:new).and_return(file_rep_noscore)
      create_form_params = {
          shas_array: %w[
            da8aa2429715ea57c142186130706315c8fc10b1b1fb2d416e63a2ed27
          ],
          disposition_suggested: FileReputationDispute::DISPOSITION_MALICIOUS,
          assignee: @current_user.cvs_username
      }

      expect do
        post '/escalations/api/v1/escalations/file_rep/disputes/form', as: :json, headers: { 'Token' => @auth_token },
             params: create_form_params
      end.to change { FileReputationDispute.count }.by(0)

      expect(response).to_not be_successful
    end

    it 'rejects SHAs which are too long' do
      allow(BugzillaRest::Session).to receive(:new).and_return(creater_session)
      allow(FileReputationDispute).to receive(:new).and_return(file_rep_noscore)
      create_form_params = {
          shas_array: %w[
            da8aa2429715ea57c142186130706315c8fc10b1b1fb2d416e63a2ed2734e104688ded
          ],
          disposition_suggested: FileReputationDispute::DISPOSITION_MALICIOUS,
          assignee: @current_user.cvs_username
      }

      expect do
        post '/escalations/api/v1/escalations/file_rep/disputes/form', as: :json, headers: { 'Token' => @auth_token },
             params: create_form_params
      end.to change { FileReputationDispute.count }.by(0)

      expect(response).to_not be_successful
    end

    it 'rejects spaces in SHAs' do
      allow(BugzillaRest::Session).to receive(:new).and_return(creater_session)
      allow(FileReputationDispute).to receive(:new).and_return(file_rep_noscore)
      create_form_params = {
          shas_array: %w[
            da8aa2429715ea57c14218613070631 5c8fc10b1b1fb2d416e63a2ed2734e104
          ],
          disposition_suggested: FileReputationDispute::DISPOSITION_MALICIOUS,
          assignee: @current_user.cvs_username
      }

      expect do
        post '/escalations/api/v1/escalations/file_rep/disputes/form', as: :json, headers: { 'Token' => @auth_token },
             params: create_form_params
      end.to change { FileReputationDispute.count }.by(0)

      expect(response).to_not be_successful
    end
  end
end
