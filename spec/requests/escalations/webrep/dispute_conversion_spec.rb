require "rails_helper"
include Warden::Test::Helpers
RSpec.describe "dispute conversion to complaints", type: :request do
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
    @dispute = Dispute.create(:ticket_source_key => 1001, :customer_id => Customer.all.first.id, :user_id => User.all.first.id, :status => "NEW")
    @dispute_entry = DisputeEntry.new
    @dispute_entry.dispute_id = @dispute.id
    @dispute_entry.uri = "test.com"
    @dispute_entry.entry_type = "URI/DOMAIN"
    @dispute_entry.platform_id = 1001
    @dispute_entry.save

    @dispute_entry2 = DisputeEntry.new
    @dispute_entry2.dispute_id = @dispute.id
    @dispute_entry2.uri = "test2.com"
    @dispute_entry2.entry_type = "URI/DOMAIN"
    @dispute_entry2.platform_id = 1001
    @dispute_entry2.save

    conversion_params = {}
    conversion_params[:dispute_id] = Dispute.all.first.id
    conversion_params[:suggested_categories] = {"0" => {"entry":"test.com","suggested_categories":"Alcohol,Adult"},"1" => {"entry":"test2.com","suggested_categories":"Alcohol,Adult"}}
    conversion_params[:summary] = "test summary"

    post '/escalations/api/v1/escalations/webrep/disputes/convert_ticket', params: conversion_params

    expect(response).to be_successful
    expect(DelayedJob.all.size).to eql(2)
    dispute = Dispute.where(ticket_source_key: 1001).first

    #check to make sure package is correct
    #check to make sure dispute and dispute entries all have correct column values saved

  end

end

# expect(response.code).to be_successful
# expect(response.code).to be_error
# expect(response.code).to be_missing
# expect(response.code).to be_redirect
