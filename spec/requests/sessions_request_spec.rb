require "rails_helper"
# require 'authentication_helper'

RSpec.describe SessionsController, type: :request do
  it 'redirects to session new when not logged in' do

    get escalations_root_path

    expect(response).to redirect_to(escalations_users_path)
  end
end
