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
            file_rep: {
                file_name: 'Steve',
                file_size: 1048576,
                # sha256_hash: 'c01b39c7a35ccc3b081a3e83d2c71fa9a767ebfeb45c69f08e17dfe3ef375a7b',
                sha256_hash: 'efb947a43bfe6d0812d105f6afdeb9774f4d79254dd48f89f1e95ffdf8732928', #threatgrid
                email: 'steve@arora.org',
                disposition_suggested: 'Malicious',
                customer: {
                    name: 'George',
                    customer_email: 'george@microsoft',
                    company_name: 'Microsoft'
                }
            },
            sender_data: {
                ticketable_type: 'FileReputationDispute',
                ticketable_id: 1001
            }
        }
    }
  end

  it 'receives file rep create messages' do
    allow(FileReputationDispute).to receive(:threaded?).and_return(false)

    expect do
      post '/escalations/peake_bridge/channels/file-rep-create/messages', as: :json,
           params: file_rep_create_message_json

      expect(response.code).to eq('200')
    end.to change { FileReputationDispute.count }
  end
end

