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

  let(:file_rep_create_message_json_not_network) do
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
                source: "talos-intelligence-api",
                payload: {
                    # sha256_hash: 'c01b39c7a35ccc3b081a3e83d2c71fa9a767ebfeb45c69f08e17dfe3ef375a7b',
                    sha256: 'efb947a43bfe6d0812d105f6afdeb9774f4d79254dd48f89f1e95ffdf8732928', #threatgrid
                    customer_email: 'steve@arora.org',
                    customer_name: 'George',
                    company_name: "Microsoft",
                    disposition_suggested: 'Malicious',
                    summary_description: "What do i do to improve the reputation",
                    sandbox_key: "TI-Form",
                    product_platform: "test_platform",
                    product_version: "test_platform_version",
                    network: false
                }
            }

        }
    }
  end

  let(:file_rep_create_message_json_in_network) do
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
                    sandbox_key: "TI-Form",
                    product_platform: "test_platform",
                    product_version: "test_platform_version",
                    network: true
                }
            }

        }
    }
  end

  before(:all) do
    FactoryBot.create(:current_user)
    FactoryBot.create(:vrt_incoming_user)

    Bug.destroy_all
  end

  it 'receives file rep create messages' do
    guest_company

    allow(FileReputationDispute).to receive(:threaded?).and_return(false)

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json,
         params: file_rep_create_message_json

    expect(response.code).to eql('200')
    file_rep_dispute = FileReputationDispute.where(ticket_source_key: 1001).first

    expect(file_rep_dispute).to_not be_nil
    expect(file_rep_dispute.source).to eql("talos-intelligence")

  end

  it 'receives file rep payload from TI API not in-network' do
    guest_company

    allow(FileReputationDispute).to receive(:threaded?).and_return(false)

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json,
         params: file_rep_create_message_json_not_network

    expect(response.code).to eql('200')
    file_rep_dispute = FileReputationDispute.where(ticket_source_key: 1001).first

    expect(file_rep_dispute).to_not be_nil
    expect(file_rep_dispute.source).to eql("talos-intelligence-api")
    expect(file_rep_dispute.product_platform).to eql("test_platform")
    expect(file_rep_dispute.product_version).to eql("test_platform_version")
    expect(file_rep_dispute.in_network).to eql(nil)
  end

  it 'receives file rep payload from TI API in-network' do
    guest_company

    allow(FileReputationDispute).to receive(:threaded?).and_return(false)

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json,
         params: file_rep_create_message_json_in_network

    expect(response.code).to eql('200')
    file_rep_dispute = FileReputationDispute.where(ticket_source_key: 1001).first

    expect(file_rep_dispute).to_not be_nil

    expect(file_rep_dispute.product_platform).to eql("test_platform")
    expect(file_rep_dispute.product_version).to eql("test_platform_version")
    expect(file_rep_dispute.in_network).to eql(true)
    expect(file_rep_dispute.file_rep_comments.size).to eql(1)
    expect(file_rep_dispute.file_rep_comments.first.comment).to include("Dispute is [in network], IPS bugzilla bug created. Reference Bugzilla ID: #{ResearchBug.all.first.id}" )

    expect(ResearchBug.all.size).to eql(1)

  end
end

