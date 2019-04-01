require "rails_helper"

RSpec.describe "Peake-Bridge file rep create channel", type: :request do
  let(:file_rep_create_message_json) do
    {
        envelope: {
            channel: "file-rep-create",
            addressee: "analyst-console-escalations",
            sender: "talos-intelligence"
        },
        message: {
            file_rep_name: 'Steve',
            sha256_checksum: 'c01b39c7a35ccc3b081a3e83d2c71fa9a767ebfeb45c69f08e17dfe3ef375a7b',
            email: 'steve@arora.org'
        }
    }
  end

  it 'receives file rep create messages' do

    expect do
      post '/escalations/peake_bridge/channels/file-rep-create/messages', as: :json,
           params: file_rep_create_message_json

      expect(response.code).to eq('200')
    end.to change { FileRep.count }
  end
end

