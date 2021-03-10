require "rails_helper"
include Warden::Test::Helpers
RSpec.describe "complaint conversion to disputes", type: :request do
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
  after :each do
    DelayedJob.destroy_all
    Platform.destroy_all
  end
  it 'should receive a call to convert a dispute with proper params' do
    vrt_incoming
    guest_company
    login_as(current_user, :scope => :user)

    FactoryBot.create(:customer, name: customer_name, email: 'not-' + customer_email, company: existing_company)
    @complaint = Complaint.create(:ticket_source_key => 1001, :customer_id => Customer.all.first.id, :status => "NEW")
    @complaint_entry = ComplaintEntry.new
    @complaint_entry.complaint_id = @complaint.id
    @complaint_entry.ip_address = "2.3.4.5"
    @complaint_entry.platform_id = 1001
    @complaint_entry.save
    @complaint_entry2 = ComplaintEntry.new
    @complaint_entry2.complaint_id = @complaint.id
    @complaint_entry2.uri = "www.test.com"
    @complaint_entry2.platform_id = 1001
    @complaint_entry2.save
    conversion_params = {}
    conversion_params[:complaint_id] = Complaint.all.first.id
    conversion_params[:submission_type] = "e"
    conversion_params[:suggested_dispositions] = "[{\"entry\":\"2.3.4.5\",\"suggested_disposition\":\"fn\"},{\"entry\":\"www.test.com\",\"suggested_disposition\":\"fp\"}]"
    conversion_params[:summary] = "test summary"

    post '/escalations/api/v1/escalations/webcat/complaints/convert_ticket', params: conversion_params

    expect(response).to be_successful
    expect(DelayedJob.all.size).to eql(2)
    complaint = Complaint.where(ticket_source_key: 1001).first
    expect(complaint.status).to eql("COMPLETED")
    expect(complaint.complaint_entries.first.status).to eql("COMPLETED")
    expect(complaint.complaint_entries.first.resolution).to eql("INVALID")


    #check to make sure package is correct
    #check to make sure dispute and dispute entries all have correct column values saved

  end

end

# expect(response.code).to be_successful
# expect(response.code).to be_error
# expect(response.code).to be_missing
# expect(response.code).to be_redirect
