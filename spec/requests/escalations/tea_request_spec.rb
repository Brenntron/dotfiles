require "rails_helper"

# post url, params: {}, headers: {}, env: {}, xhr: false, as: :symbol

RSpec.describe API::V1::Escalations::CloudIntel::Tea, type: :request do
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



  before(:all) do
    FactoryBot.create(:customer, name: 'Dispute Analyst')
  end

  it 'get tea data on a provided uri' do
    allow(BugzillaRest::Session).to receive(:new).and_return(creater_session)

    get_data_params = {

        entry: 'www.google.com'
    }

    post '/escalations/api/v1/escalations/cloud_intel/tea/get_data', as: :json, headers: { 'Token' => @auth_token },
         params: get_data_params

    expect(response).to be_successful

    code = response.code
    body = response.body

    response_hash = JSON.parse(body)

    expect(code).to eql("201")
    expect(response_hash).to eql({})
  end



end
