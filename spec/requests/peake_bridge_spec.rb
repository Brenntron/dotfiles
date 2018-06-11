require "rails_helper"

RSpec.describe "Widget management", :type => :request do

  it 'receives unknown message' do

    post '/bridge/channels/unknown/messages'

    expect(response.code).to eq('500')
  end

  it 'receives rule_file_notify' do

    post '/bridge/channels/rule-file-notify/messages', params: {
        message: {
            filenames: [
                'trunk/snort-rules/app-detect.rules',
                'trunk/snort-rules/browser-chrome.rules',
                'trunk/snort-rules/file-office.rules'
            ]
        }
    }

    expect(response.code).to eq('202')
  end

  it 'receives fp_create'

  it 'receives fp_event'

end
