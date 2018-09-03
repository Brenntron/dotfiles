require "rails_helper"

RSpec.describe "Peake-Bridge messages miscellanious channels", :type => :request do
  it 'receives unknown message' do

    post '/escalations/peake_bridge/channels/unknown/messages'

    expect(response.code).to eq('400')
  end
end
