require "rails_helper"

RSpec.describe "Peake-Bridge file rep create channel", type: :request do
  let(:file_rep_create_message_json) do
    {}
  end

  it 'receives file rep create messages' do

    post '/escalations/peake_bridge/channels/file-rep-create/messages', as: :json, params: file_rep_create_message_json

  end
end

