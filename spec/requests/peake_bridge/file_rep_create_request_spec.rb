require "rails_helper"

RSpec.describe "Peake-Bridge file rep create channel", type: :request do

  let(:guest_company) { FactoryBot.create(:guest_company) }
  let(:company_name) { 'WRMC' }
  let(:customer_name) { '3-Support Support' }
  let(:customer_email) { 'webmaster@cmim.org' }
  let(:existing_company) { FactoryBot.create(:company, name: company_name) }

  let(:file_rep_create_message_json) do
    {
        envelope: {
            channel: "ticket-event",
            addressee: "analyst-console-escalations",
            sender: "talos-intelligence"
        },
        message: {
            file_reputation_dispute: {
                source_key: 1001,
                source_type: "FileReputationDispute",
                payload: {
                    # sha256_hash: 'c01b39c7a35ccc3b081a3e83d2c71fa9a767ebfeb45c69f08e17dfe3ef375a7b',
                    sha256: 'efb947a43bfe6d0812d105f6afdeb9774f4d79254dd48f89f1e95ffdf8732928', #threatgrid
                    customer_email: 'steve@arora.org',
                    customer_name: 'George',
                    company_name: "Microsoft",
                    disposition_suggested: 'Malicious',
                    summary_description: "What do i do to improve the reputation",
                    sandbox_key: "TI-Form"
                }
            }

        }
    }

  end

  before(:all) do
    FactoryBot.create(:current_user)
    FactoryBot.create(:vrt_incoming_user)
  end

  it 'receives file rep create messages' do
    allow(FileReputationDispute).to receive(:threaded?).and_return(false)

    expect do
      post '/escalations/peake_bridge/channels/file-rep-create/messages', as: :json,
           params: file_rep_create_message_json

      expect(response.code).to eq('200')
    end.to change { FileReputationDispute.count }
  end

  it 'should short circuit ticket creation from payload if the ticket already exists (to prevent dupes)' do

    guest_company
    FactoryBot.create(:customer, name: customer_name, email: 'not-' + customer_email, company: existing_company)
    FileReputationDispute.create(:ticket_source_key => 1001, :customer_id => Customer.all.first.id, :user_id => User.all.first.id, :status => "NEW", :disposition_suggested => "Malicious", :sha256_hash => "efb947a43bfe6d0812d105f6afdeb9774f4d79254dd48f89f1e95ffdf8732928")

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json,
         params: file_rep_create_message_json

    expect(response).to be_successful
    dispute = FileReputationDispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(FileReputationDispute.all.size).to eql(1)
    expect(DelayedJob.all.size).to eql(1)

  end
end

