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

  after :each do
    DelayedJob.destroy_all
  end
  it 'should receive a call to convert a dispute with proper params' do
    vrt_incoming
    guest_company
    login_as(current_user, :scope => :user)

    FactoryBot.create(:customer, name: customer_name, email: 'not-' + customer_email, company: existing_company)
    @complaint = Complaint.create(:ticket_source_key => 1001, :customer_id => Customer.all.first.id, :status => "NEW")
    @complaint_entry = ComplaintEntry.new
    @complaint_entry.complaint_id = @complaint.id
    @complaint_entry.uri = "test.com"
    @complaint_entry.save
    conversion_params = {}
    conversion_params[:complaint_id] = Complaint.all.first.id
    conversion_params[:suggested_dispositions] = "[{\"test\":1},{\"test2\":2}]"
    conversion_params[:summary] = "test summary"

    post '/escalations/api/v1/escalations/webcat/complaints/convert_ticket', params: conversion_params

    expect(response).to be_successful
    expect(DelayedJob.all.size).to eql(2)
    complaint = Complaint.where(ticket_source_key: 1001).first

    #check to make sure package is correct
    #check to make sure dispute and dispute entries all have correct column values saved

  end

end

# expect(response.code).to be_successful
# expect(response.code).to be_error
# expect(response.code).to be_missing
# expect(response.code).to be_redirect
