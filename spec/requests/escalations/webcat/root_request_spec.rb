require "rails_helper"
require 'authentication_helper'

RSpec.describe Escalations::Webcat::RootController, :type => :request do
  it 'redirects index routes to complaints index' do
    create_login_session(roles: ['webcat user'])

    get '/escalations/webcat'

    expect(response).to redirect_to('/escalations/webcat/complaints')
  end
end
