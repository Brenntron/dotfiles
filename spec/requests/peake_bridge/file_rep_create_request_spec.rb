require "rails_helper"

RSpec.describe "Peake-Bridge file rep create channel", type: :request do

  let(:guest_company) { FactoryBot.create(:guest_company) }
  let(:company_name) { 'WRMC' }
  let(:customer_name) { '3-Support Support' }
  let(:customer_email) { 'webmaster@cmim.org' }
  let(:existing_company) { FactoryBot.create(:company, name: company_name) }


  let(:file_rep_create_message_json_fp) do
    {
        envelope: {
            channel: "ticket-event",
            addressee: "analyst-console-escalations",
            sender: "talos-intelligence"
        },
        message: {
            file_reputation_dispute: {
                source_key: 1005,
                source_type: "FileReputationDispute",
                payload: {
                    # sha256_hash: 'c01b39c7a35ccc3b081a3e83d2c71fa9a767ebfeb45c69f08e17dfe3ef375a7b',
                    sha256: 'efb947a43bfe6d0812d105f6afdeb9774f4d79254dd48f89f1e95ffdf8732928', #threatgrid
                    customer_email: 'steve@arora.org',
                    customer_name: 'George',
                    company_name: "Microsoft",
                    disposition_suggested: 'Clean',
                    summary_description: "What do i do to improve the reputation",
                    sandbox_key: "TI-Form",
                    product_platform: 1001

                }
            }

        }
    }
  end

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
                  sandbox_key: "TI-Form",
                  product_platform: 1001

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
                    product_platform: 1001,
                    product_version: "test_platform_version",
                    network: false,
                    meta_data: "{\"ticket\":{\"testing_ticket\":123},\"entry\":{\"testing_entry\":123}}"
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
                    product_platform: 1001,
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

    allow(FileReputationDispute).to receive(:threaded?).and_return(false)

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json,
         params: file_rep_create_message_json

    expect(response.code).to eql('200')
    file_rep_dispute = FileReputationDispute.where(ticket_source_key: 1001).first

    expect(file_rep_dispute).to_not be_nil
    expect(file_rep_dispute.source).to eql("talos-intelligence")
    expect(file_rep_dispute.platform_id).to eql(1001)
    expect(file_rep_dispute.ti_product_platform).to eql(@original_platform)
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
    expect(file_rep_dispute.product_platform).to eql(nil)
    expect(file_rep_dispute.product_version).to eql("test_platform_version")
    expect(file_rep_dispute.in_network).to eql(nil)
    expect(file_rep_dispute.meta_data).to eql("{\"ticket\":{\"testing_ticket\":123},\"entry\":{\"testing_entry\":123}}")
    expect(file_rep_dispute.platform_id).to eql(1001)
  end

  it 'receives file rep payload from TI API in-network' do
    guest_company

    allow(FileReputationDispute).to receive(:threaded?).and_return(false)

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json,
         params: file_rep_create_message_json_in_network

    expect(response.code).to eql('200')
    file_rep_dispute = FileReputationDispute.where(ticket_source_key: 1001).first

    expect(file_rep_dispute).to_not be_nil

    expect(file_rep_dispute.product_platform).to eql(nil)
    expect(file_rep_dispute.product_version).to eql("test_platform_version")
    expect(file_rep_dispute.in_network).to eql(true)
    expect(file_rep_dispute.file_rep_comments.size).to eql(1)
    expect(file_rep_dispute.file_rep_comments.first.comment).to include("Dispute is [in network], IPS bugzilla bug created. Reference Bugzilla ID: #{ResearchBug.all.first.id}" )
    expect(file_rep_dispute.platform_id).to eql(1001)
    expect(ResearchBug.all.size).to eql(1)

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


  it 'should set to no file comment when does not exist in all sources for FN' do

    guest_company
    FactoryBot.create(:customer, name: customer_name, email: 'not-' + customer_email, company: existing_company)

    ReversingLabResponse = Struct.new(:raw_json)
    rlab_bad = ReversingLabResponse.new
    rlab_bad.raw_json = "{\"error\":\"Not in RL\"}"



    expect(Threatgrid::Search).to receive(:query).with(anything).and_return({}).at_least(:once)
    expect(FileReputationApi::ReversingLabs).to receive(:lookup).with(anything).and_return(rlab_bad).at_least(:once)

    expect(FileReputationApi::SampleZoo).to receive(:sha256_lookup).with(anything).and_return({"hits" => {"total" => 0}}).at_least(:once)

    expect(FileReputationApi::Sandbox).to receive(:sample_exists).with(anything, :api_key_type => anything).and_return(false).at_least(:once)


    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json,
         params: file_rep_create_message_json

    expect(response).to be_successful
    dispute = FileReputationDispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(FileReputationDispute.all.size).to eql(1)
    expect(DelayedJob.all.size).to eql(1)

    expect(dispute.status).to eql("RESOLVED_CLOSED")
    expect(dispute.resolution).to eql("AP - No File")


  end

  it 'should set to new if FN and no existence specifically in both sandbox and malware zoo (but present in others)' do

    guest_company
    FactoryBot.create(:customer, name: customer_name, email: 'not-' + customer_email, company: existing_company)

    ReversingLabResponse = Struct.new(:raw_json)
    rlab_bad = ReversingLabResponse.new
    rlab_bad.raw_json = "{\"result\":\"some data\"}"


    expect(Threatgrid::Search).to receive(:query).with(anything).and_return({:threatgrid_score => 20}).at_least(:once)
    expect(FileReputationApi::ReversingLabs).to receive(:lookup).with(anything).and_return(rlab_bad).at_least(:once)

    expect(FileReputationApi::SampleZoo).to receive(:sha256_lookup).with(anything).and_return({}).at_least(:once)

    expect(FileReputationApi::Sandbox).to receive(:sample_exists).with(anything, :api_key_type => anything).and_return({}).at_least(:once)


    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json,
         params: file_rep_create_message_json

    expect(response).to be_successful
    dispute = FileReputationDispute.where(ticket_source_key: 1001).first

    expect(dispute).to_not be_nil
    expect(FileReputationDispute.all.size).to eql(1)
    expect(DelayedJob.all.size).to eql(1)

    expect(dispute.status).to eql("NEW")
  end

  it 'should set to new if FP and no existence in reversing lab' do
    FileReputationDispute.destroy_all
    ReversingLabResponse = Struct.new(:raw_json)
    rlab_bad = ReversingLabResponse.new
    rlab_bad.raw_json = "{\"error\":\"Not in RL\"}"

    AmpResponse = Struct.new(:disposition, :name)
    amp_bad = AmpResponse.new
    amp_bad.disposition = "Test"
    amp_bad.name = "Test"


    guest_company
    FactoryBot.create(:customer, name: customer_name, email: 'not-' + customer_email, company: existing_company)

    expect(Threatgrid::Search).to receive(:query).with(anything).and_return({:threatgrid_score => 20}).at_least(:once)
    expect(FileReputationApi::ReversingLabs).to receive(:lookup).with(anything).and_return(rlab_bad).at_least(:once)

    expect(FileReputationApi::SampleZoo).to receive(:sha256_lookup).with(anything).and_return({}).at_least(:once)

    expect(FileReputationApi::Sandbox).to receive(:sample_exists).with(anything, :api_key_type => anything).and_return({}).at_least(:once)

    expect(FileReputationApi::Detection).to receive(:get_bulk).with(anything).and_return(amp_bad).at_least(:once)

    post '/escalations/peake_bridge/channels/ticket-event/messages', as: :json,
         params: file_rep_create_message_json_fp

    expect(response).to be_successful
    dispute = FileReputationDispute.where(ticket_source_key: 1005).first

    expect(dispute).to_not be_nil
    expect(FileReputationDispute.all.size).to eql(1)
    expect(DelayedJob.all.size).to eql(1)

    expect(dispute.status).to eql("NEW")
    has_text = dispute.auto_resolve_log.include?("no files in Reversing Lab")
    expect(has_text).to eql(true)

  end
end

