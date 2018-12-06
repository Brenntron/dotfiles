require "rails_helper"
require 'authentication_helper'

RSpec.describe Escalations::Webrep::RootController, type: :request do
  it 'redirects index routes to complaints index' do
    create_login_session(roles: ['webcat user'])

    get '/escalations/webrep'

    expect(response).to redirect_to('/escalations/webrep/disputes')
  end
end
