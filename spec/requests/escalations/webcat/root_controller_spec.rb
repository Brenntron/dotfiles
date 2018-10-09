require "rails_helper"
require 'authentication_helper'

RSpec.describe Escalations::WebcatController, :type => :request do
  it 'redirects index routes to complaints index' do
    # sign_in_as_a_valid_user
    # data = login_sesssion_data
    # byebug
    # login_session(session)
    # login

    user = FactoryBot.create(:current_user)
    user.roles << FactoryBot.create(:role, role: 'webcat user')
    post user_session_path,
         headers: {'REMOTE_USER' => user.cvs_username,
                   'AUTHORIZE_MAIL' => user.email,
         },
         params: {'uname' => Rails.configuration.bugzilla_username,
                  'psw' => Rails.configuration.bugzilla_password}

    # get '/escalations/webcat', {}, login_session_data
    # get '/escalations/webcat', session: data
    byebug
    get '/escalations/webcat'

    expect(response).to redirect_to('/escalations/webcat/complaints')
    # expect(response).to redirect_to(new_escalations_session_path)
  end

  it "gives session" do
    byebug
    session[:user_id] = 12
    expect(session[:user_id]).to eq(12)
  end
end
