require "rails_helper"

RSpec.describe "Peake-Bridge sdr rep create channel", type: :request do

  let(:guest_company) { FactoryBot.create(:guest_company) }
  let(:company_name) { 'WRMC' }
  let(:customer_name) { '3-Support Support' }
  let(:customer_email) { 'webmaster@cmim.org' }
  let(:existing_company) { FactoryBot.create(:company, name: company_name) }


  let(:sdr_rep_create_message_json) do
    {
        envelope: {
            channel: "ticket-event",
            addressee: "analyst-console-escalations",
            sender: "talos-intelligence"
        },
        message: {
            sender_domain_reputation_dispute: {
                source_key: 1005,
                source_type: "SenderDomainReputationDispute",
                payload: {
                    sender_domain_entry: 'test.com', #threatgrid
                    customer_email: 'steve@arora.org',
                    customer_name: 'George',
                    company_name: "Microsoft",
                    suggested_disposition: 'False Positive',
                    summary_description: "What do i do to improve the reputation",
                    platform: 1001

                }
            }

        }
    }
  end

  before(:all) do
    FactoryBot.create(:current_user)
    FactoryBot.create(:vrt_incoming_user)

    Bug.destroy_all
    SenderDomainReputationDispute.destroy_all
    SenderDomainReputationDisputeAttachment.destroy_all
    DelayedJob.destroy_all
  end

  before(:each) do
    @original_platform = Platform.new
    @original_platform.id = 1001
    @original_platform.public_name = "test"
    @original_platform.internal_name = "test internal"
    @original_platform.active = true
    @original_platform.webrep = true
    @original_platform.webcat = true
    @original_platform.filerep = true
    @original_platform.emailrep = true
    @original_platform.save
  end

  after(:each) do
    Platform.destroy_all
  end

  it 'receives file rep create messages' do
    guest_company

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json,
         params: sdr_rep_create_message_json

    expect(response.code).to eql('200')
    sdr_rep_dispute = SenderDomainReputationDispute.where(ticket_source_key: 1005).first

    expect(sdr_rep_dispute).to_not be_nil
    expect(sdr_rep_dispute.source).to eql("talos-intelligence")
    expect(sdr_rep_dispute.platform_id).to eql(1001)
    expect(sdr_rep_dispute.suggested_disposition).to eql("False Positive")
    expect(sdr_rep_dispute.sender_domain_entry).to eql("test.com")
    expect(sdr_rep_dispute.description).to eql("What do i do to improve the reputation")
    expect(DelayedJob.all.size).to eql(1)
  end

end

