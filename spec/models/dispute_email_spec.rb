describe DisputeEmail do

  let(:bug_factory) do
    double('Bugzilla::Bug', create: { "id" => 101 })
  end

  before(:all) do
    @vrt_incoming = FactoryBot.create(:vrt_incoming_user)
    @current_user = FactoryBot.create(:current_user)
    FactoryBot.create(:guest_company)
  end

  before(:each) do
    DisputeEmail.destroy_all
    DelayedJob.destroy_all
  end

  it 'should be able to process meta data when sending emails (dispute)' do

    dispute = Dispute.new
    dispute.id = 12345
    dispute.meta_data = {:ticket => {}, :entry => {:cc => "test_cc@test.com"}}.to_json
    dispute.save(:validate => false)

    bugzilla_rest_session = BugzillaRest::Session.default_session
    params = {}
    params[:dispute_id] = dispute.id
    params[:to] = "test_1@test.com"
    params[:cc] = "test_2@test.com"
    params[:subject] = "test subject"
    params[:body] = "test body"
    params[:dispute_type] = "Dispute"
    current_user = @current_user

    DisputeEmail.create_email_and_send(params, bugzilla_rest_session: bugzilla_rest_session, current_user: current_user)

    expect(DisputeEmail.all.size).to eql(1)
    expect(DisputeEmail.all.first.to).to eql("test_1@test.com,test_2@test.com,test_cc@test.com")

  end

  it 'should be able to process meta data when sending emails (file rep dispute)' do

    dispute = FileReputationDispute.new
    dispute.id = 12345
    dispute.meta_data = {:ticket => {}, :entry => {:cc => "test_cc@test.com, test_cc_2@test.com"}}.to_json
    dispute.save(:validate => false)

    bugzilla_rest_session = BugzillaRest::Session.default_session
    params = {}
    params[:dispute_id] = dispute.id
    params[:to] = "test_1@test.com, test_11@test.com"
    params[:cc] = "test_2@test.com, test_3@test.com"
    params[:subject] = "test subject"
    params[:body] = "test body"
    params[:dispute_type] = "FileReputationDispute"

    current_user = @current_user

    DisputeEmail.create_email_and_send(params, bugzilla_rest_session: bugzilla_rest_session, current_user: current_user)

    expect(DisputeEmail.all.size).to eql(1)
    expect(DisputeEmail.all.first.to).to eql("test_1@test.com,test_11@test.com,test_2@test.com,test_3@test.com,test_cc@test.com,test_cc_2@test.com")
  end

  it 'should be able to process email with no meta data' do

    dispute = FileReputationDispute.new
    dispute.id = 12345
    dispute.save(:validate => false)

    bugzilla_rest_session = BugzillaRest::Session.default_session
    params = {}
    params[:dispute_id] = dispute.id
    params[:to] = "test_1@test.com, test_11@test.com"
    params[:cc] = "test_2@test.com, test_3@test.com"
    params[:subject] = "test subject"
    params[:body] = "test body"
    params[:dispute_type] = "FileReputationDispute"

    current_user = @current_user

    DisputeEmail.create_email_and_send(params, bugzilla_rest_session: bugzilla_rest_session, current_user: current_user)

    expect(DisputeEmail.all.size).to eql(1)
    expect(DisputeEmail.all.first.to).to eql("test_1@test.com,test_11@test.com,test_2@test.com,test_3@test.com")

  end

end
