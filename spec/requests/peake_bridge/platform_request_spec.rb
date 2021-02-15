require "rails_helper"

RSpec.describe "Peake-Bridge platform channel", type: :request do

  let(:guest_company) { FactoryBot.create(:guest_company) }
  let(:company_name) { 'WRMC' }
  let(:customer_name) { '3-Support Support' }
  let(:customer_email) { 'webmaster@cmim.org' }
  let(:existing_company) { FactoryBot.create(:company, name: company_name) }

  let(:platform_create_message_json) do
    {
        envelope: {
            channel: "ticket-event",
            addressee: "analyst-console-escalations",
            sender: "talos-intelligence"
        },
        message: {
            platform: {
                action: "create",
                source_key: 1001,
                source_type: "Platform",
                attributes: {
                    id: 1001,
                    public_name: "test",
                    internal_name: "test internal",
                    active: true,
                    webrep: true,
                    webcat: true,
                    filerep: true,
                    emailrep: true
                }
            }
        }
    }
  end

  let(:platform_update_message_json) do
    {
        envelope: {
            channel: "ticket-event",
            addressee: "analyst-console-escalations",
            sender: "talos-intelligence"
        },
        message: {
            platform: {
                action: "update",
                source_key: 1001,
                source_type: "Platform",
                attributes: {
                    id: 1001,
                    public_name: "test2",
                    internal_name: "test internal2",
                    active: true,
                    webrep: true,
                    webcat: true,
                    filerep: true,
                    emailrep: true
                }
            }
        }
    }
  end

  let(:platform_destroy_message_json) do
    {
        envelope: {
            channel: "ticket-event",
            addressee: "analyst-console-escalations",
            sender: "talos-intelligence"
        },
        message: {
            platform: {
                action: "destroy",
                source_key: 1001,
                source_type: "Platform",
                attributes: {
                    id: 1001

                }
            }
        }
    }
  end

  before(:all) do
    FactoryBot.create(:current_user)
    FactoryBot.create(:vrt_incoming_user)
    Platform.destroy_all
    Bug.destroy_all
  end

  before(:each) do
    Platform.destroy_all
  end

  it 'receives platform create message' do
    guest_company

    #allow(FileReputationDispute).to receive(:threaded?).and_return(false)

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json,
         params: platform_create_message_json

    expect(response.code).to eql('200')
    platform = Platform.where(:id => 1001).first

    expect(platform).to_not be_nil

  end

  it 'receives platform update message' do
    guest_company

    original_platform = Platform.new
    original_platform.id = 1001
    original_platform.public_name = "test"
    original_platform.internal_name = "test internal"
    original_platform.active = true
    original_platform.webrep = true
    original_platform.webcat = true
    original_platform.filerep = true
    original_platform.emailrep = true
    original_platform.save

    original_platform.reload

    expect(original_platform.id).to eql(1001)
    expect(original_platform.public_name).to eql('test')
    expect(original_platform.internal_name).to eql('test internal')
    #allow(FileReputationDispute).to receive(:threaded?).and_return(false)

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json,
         params: platform_update_message_json

    expect(response.code).to eql('200')
    platform = Platform.where(:id => 1001).first
    expect(platform).to_not be_nil
    expect(platform.public_name).to eql('test2')
    expect(platform.internal_name).to eql('test internal2')

  end

  it 'receives platform destroy message' do
    guest_company

    original_platform = Platform.new
    original_platform.id = 1001
    original_platform.public_name = "test"
    original_platform.internal_name = "test internal2"
    original_platform.active = true
    original_platform.webrep = true
    original_platform.webcat = true
    original_platform.filerep = true
    original_platform.emailrep = true
    original_platform.save

    original_platform.reload

    expect(original_platform.id).to eql(1001)
    expect(original_platform.public_name).to eql('test')
    expect(original_platform.internal_name).to eql('test internal2')
    #allow(FileReputationDispute).to receive(:threaded?).and_return(false)

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json,
         params: platform_destroy_message_json

    expect(response.code).to eql('200')
    platform = Platform.where(:id => 1001).first
    expect(platform).to be_nil

  end

  it 'should create a new platform out of archive' do
    guest_company

    original_platform = Platform.new
    original_platform.id = 2001
    original_platform.public_name = "test"
    original_platform.internal_name = "test internal"
    original_platform.active = true
    original_platform.webrep = true
    original_platform.webcat = true
    original_platform.filerep = true
    original_platform.emailrep = true
    original_platform.save

    original_platform.reload

    expect(original_platform.id).to eql(2001)
    expect(original_platform.public_name).to eql('test')
    expect(original_platform.internal_name).to eql('test internal')
    #allow(FileReputationDispute).to receive(:threaded?).and_return(false)

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json,
         params: platform_update_message_json

    expect(response.code).to eql('200')
    platform = Platform.where(:id => 1001).first
    expect(platform).to_not be_nil
    expect(platform.public_name).to eql('test2')
    expect(platform.internal_name).to eql('test internal2')

  end
end

