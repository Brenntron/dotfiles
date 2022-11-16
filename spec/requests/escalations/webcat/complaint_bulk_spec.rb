require "rails_helper"
include Warden::Test::Helpers
RSpec.describe "complaint bulk submit", type: :request do
  let(:vrt_incoming) { FactoryBot.create(:vrt_incoming_user) }
  let(:guest_company) { FactoryBot.create(:guest_company) }
  let(:company_name) { 'WRMC' }
  let(:customer_name) { '3-Support Support' }
  let(:customer_email) { 'webmaster@cmim.org' }
  let(:current_user) { FactoryBot.create(:current_user) }
  let(:existing_company) { FactoryBot.create(:company, name: company_name) }
  let(:existing_customer) do
    FactoryBot.create(:customer, name: customer_name, email: customer_email, company: existing_company)
  end
  before :each do
    Complaint.destroy_all
    ComplaintEntry.destroy_all


    @original_platform = Platform.new
    @original_platform.id = 1001
    @original_platform.public_name = "talosintelligence.com"
    @original_platform.internal_name = "talosintelligence.com"
    @original_platform.active = true
    @original_platform.webrep = true
    @original_platform.webcat = true
    @original_platform.filerep = true
    @original_platform.emailrep = true
    @original_platform.save
  end
  after :each do
    DelayedJob.destroy_all
    Platform.destroy_all
  end
  it 'should bulk submit one entry with one category' do
    vrt_incoming
    guest_company
    login_as(current_user, :scope => :user)

    bulk_params = {}
    bulk_params[:entries] = ["test-one.com"]
    bulk_params[:categories] = ["Business and Industry"]
    bulk_params[:category_ids] = ["10"]

    post '/escalations/api/v1/escalations/webcat/complaints/bulk_categorize', params: bulk_params

    expect(response).to be_successful
    json_body = JSON.parse(response.body)
    expect(json_body["status"]).to eql("success")
    expect(json_body["data"]["created"].size).to eql(1)
    expect(json_body["data"]["completed"].size).to eql(1)

    current_cats = Wbrs::Prefix.where({:urls => [URI.escape('test-one.com')]})
    expect(current_cats.size).to eql(1)
    expect(current_cats.first.category_id).to eql(10)

    #check to make sure package is correct
    #check to make sure dispute and dispute entries all have correct column values saved

  end

  it 'should bulk submit multiple entry with multiple category' do
    vrt_incoming
    guest_company
    login_as(current_user, :scope => :user)

    bulk_params = {}
    bulk_params[:entries] = ["test-six.com", "test-seven.com"]
    bulk_params[:categories] = ["Business and Industry", "Alcohol"]
    bulk_params[:category_ids] = ["15", "16"]

    post '/escalations/api/v1/escalations/webcat/complaints/bulk_categorize', params: bulk_params

    expect(response).to be_successful
    json_body = JSON.parse(response.body)
    expect(json_body["status"]).to eql("success")
    expect(json_body["data"]["created"].size).to eql(2)
    expect(json_body["data"]["completed"].size).to eql(2)

    current_cats = Wbrs::Prefix.where({:urls => [URI.escape('test-six.com')]})
    expect(current_cats.size).to eql(2)
    expect(current_cats.first.category_id).to eql(15)
    expect(current_cats.last.category_id).to eql(16)

    current_cats = Wbrs::Prefix.where({:urls => [URI.escape('test-seven.com')]})
    expect(current_cats.size).to eql(2)
    expect(current_cats.first.category_id).to eql(15)
    expect(current_cats.last.category_id).to eql(16)

  end

end

# expect(response.code).to be_successful
# expect(response.code).to be_error
# expect(response.code).to be_missing
# expect(response.code).to be_redirect
