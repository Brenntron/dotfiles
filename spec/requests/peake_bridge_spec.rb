require "rails_helper"

RSpec.describe "Widget management", :type => :request do

  it 'receives unknown message' do

    post '/bridge/channels/unknown/messages'

    expect(response.code).to eq('500')
  end

  it 'receives fp_create' do
    allow(Thread).to receive(:new)

    post '/bridge/channels/fp-event/messages', params: {
        envelope: {
            channel: "fp-create",
            addressee: "analyst-console",
            sender: "snort-org"
        },
        message: {
            user_email: 'customer@mainstreet.com',
            source_key: 101,
            fp_attrs: {
                sid: 'I think it is 1019',
                os: 'VMS',
                cmd_line_options: '-h'
            }
        }
    }

    expect(response.code).to eq('200')
  end

  it 'receives fp_event from snort.org' do
    allow(Thread).to receive(:new)

    post '/bridge/channels/fp-event/messages', params: {
        envelope: {
            channel: "fp-event",
            addressee: "analyst-console",
            sender: "snort-org"
        },
        message: {
            user_email: 'customer@mainstreet.com',
            source_key: 101,
            fp_attrs: {
                sid: 'I think it is 1019',
                os: 'VMS',
                cmd_line_options: '-h'
            }
        }
    }

    expect(response.code).to eq('200')
  end

end
