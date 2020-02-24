require "rails_helper"
require 'authentication_helper'

RSpec.describe Escalations::Webcat::RootController, type: :request do
  let(:guest_company) { FactoryBot.create(:guest_company) }

  it 'redirects index routes to complaints index' do
    guest_company
    create_login_session(roles: ['webcat user'])

    get '/escalations/webcat'

    expect(response).to redirect_to('/escalations/webcat/complaints')
  end
end
