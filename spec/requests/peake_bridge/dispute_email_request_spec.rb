require "rails_helper"

RSpec.describe "Peake-Bridge dispute email messages channels", type: :request do
  let(:customer) { FactoryBot.create(:customer) }
  let(:dispute) { FactoryBot.create(:dispute, customer: customer) }

  it 'receives dispute email payload messages' do

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json, params: {
        envelope: {
            channel: "ticket-event",
            addressee: "analyst-console-escalations",
            sender: "talos-intelligence"
        },
        message: {
            dispute_email: {
                source_type: 'DisputeEmail',
                source_key: 1001,
                payload: {
                    envelope: {
                        from: 'paulo@capterra.com',
                        to: [ 'marlpier@cisco.com' ],
                    }.to_json,
                    from: 'paulo@capterra.com',
                    to: [ 'marlpier@cisco.com' ],
                    text: "ref-#{dispute.id}-anco",
                    headers: '',
                    name: 'reputation deal',
                    email: '',
                    domain: 'capterra.com',
                    problem: 'What is its deal?',
                    details: 'I just want to know what its deal is.',
                    user_ip: '54.156.208.110',
                    ticket_time: Time.now - 30,
                    investigate_ips: {},
                    investigate_urls: {},
                    email_subject: 'This reputation stuff',
                    email_body: 'What is the deal with the reputation stuff?',
                    user_company: 'Capterra',
                },
                attachments: [],
            }
        }
    }

    expect(response).to be_success
    dispute_email = DisputeEmail.where(dispute_id: dispute.id).first
    expect(dispute_email).to_not be_nil
  end
end
