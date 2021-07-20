require "rails_helper"
require 'authentication_helper'

RSpec.describe Escalations::Webcat::RootController, type: :request do

  let(:creater_session) do
    bug_proxy = BugzillaRest::BugProxy.new({id: 101101}, api_key: nil, token: nil)
    double('BugzillaRest::Session', create_bug: bug_proxy)
  end

  before(:all) do
    @current_user = FactoryBot.create(:current_user)
    @current_user.roles << FactoryBot.create(:web_cat_role)
    @username = @current_user.cvs_username
    @auth_token = @current_user.authentication_token

    @platform = Platform.new
    @platform.id = 1001
    @platform.public_name = "test"
    @platform.internal_name = "test internal"
    @platform.active = true
    @platform.webrep = true
    @platform.webcat = true
    @platform.filerep = true
    @platform.emailrep = true
    @platform.save

    @platform2 = Platform.new
    @platform2.id = 1002
    @platform2.public_name = "test2"
    @platform2.internal_name = "test2 internal2"
    @platform2.active = true
    @platform2.webrep = true
    @platform2.webcat = true
    @platform2.filerep = true
    @platform2.emailrep = true
    @platform2.save
  end


  #for reporting


  it 'api report returns 3 of 4 complaint entries within a time range' do
    allow(BugzillaRest::Session).to receive(:new).and_return(creater_session)

    complaint_entry_one = FactoryBot.create(:complaint_entry)
    complaint_entry_two = FactoryBot.create(:complaint_entry)
    complaint_entry_three = FactoryBot.create(:complaint_entry)
    complaint_entry_four = FactoryBot.create(:complaint_entry)

    complaint_entry_one.case_assigned_at = 28.days.ago
    complaint_entry_two.case_assigned_at = 27.days.ago
    complaint_entry_three.case_assigned_at = 26.days.ago
    complaint_entry_four.case_assigned_at = 90.days.ago

    complaint_entry_one.save
    complaint_entry_two.save
    complaint_entry_three.save
    complaint_entry_four.save

    complaint = complaint_entry_one.complaint
    complaint.platform_id = @platform.id
    complaint.save

    complaint = complaint_entry_two.complaint
    complaint.platform_id = @platform.id
    complaint.save

    complaint_entry_three.platform_id = @platform2.id
    complaint_entry_three.save

    complaint_entry_four.platform_id = @platform2.id
    complaint_entry_four.save

    range_from = 30.days.ago.to_s.gsub(" ", "+")
    range_to = 20.days.ago.to_s.gsub(" ", "+")

    get "/escalations/api/v1/escalations/webcat/complaints/complaint_report_stats?date_from=#{range_from}&date_to=#{range_to}", headers: { 'Token' => @auth_token }


    json_response = JSON.parse(JSON.parse(response.body))
    
    expect(json_response["count"]).to equal 3

  end

  it 'api report returns 3 results for the same complaint entry when multiple timestamps fit in datetime range' do
    allow(BugzillaRest::Session).to receive(:new).and_return(creater_session)

    complaint_entry_one = FactoryBot.create(:complaint_entry)

    complaint_entry_one.created_at = 28.days.ago
    complaint_entry_one.case_assigned_at = 27.days.ago
    complaint_entry_one.case_resolved_at = 26.days.ago


    complaint_entry_one.save

    range_from = 30.days.ago.to_s.gsub(" ", "+")
    range_to = 20.days.ago.to_s.gsub(" ", "+")

    get "/escalations/api/v1/escalations/webcat/complaints/complaint_report_stats?date_from=#{range_from}&date_to=#{range_to}", headers: { 'Token' => @auth_token }


    json_response = JSON.parse(JSON.parse(response.body))

    expect(json_response["count"]).to equal 3

  end

  it 'api report returns 0 results when not in date time range' do
    allow(BugzillaRest::Session).to receive(:new).and_return(creater_session)

    complaint_entry_one = FactoryBot.create(:complaint_entry)
    complaint_entry_two = FactoryBot.create(:complaint_entry)
    complaint_entry_three = FactoryBot.create(:complaint_entry)
    complaint_entry_four = FactoryBot.create(:complaint_entry)

    complaint_entry_one.case_assigned_at = 28.days.ago
    complaint_entry_two.case_assigned_at = 27.days.ago
    complaint_entry_three.case_assigned_at = 26.days.ago
    complaint_entry_four.case_assigned_at = 90.days.ago

    complaint_entry_one.save
    complaint_entry_two.save
    complaint_entry_three.save
    complaint_entry_four.save



    range_from = 40.days.ago.to_s.gsub(" ", "+")
    range_to = 30.days.ago.to_s.gsub(" ", "+")

    get "/escalations/api/v1/escalations/webcat/complaints/complaint_report_stats?date_from=#{range_from}&date_to=#{range_to}", headers: { 'Token' => @auth_token }

    json_response = JSON.parse(JSON.parse(response.body))

    expect(json_response["count"]).to equal 0

  end

  it 'api report returns 3 results mixed timestamps when in date time range' do
    allow(BugzillaRest::Session).to receive(:new).and_return(creater_session)

    complaint_entry_one = FactoryBot.create(:complaint_entry)
    complaint_entry_two = FactoryBot.create(:complaint_entry)
    complaint_entry_three = FactoryBot.create(:complaint_entry)


    complaint_entry_one.case_assigned_at = 28.days.ago
    complaint_entry_two.case_resolved_at = 27.days.ago
    complaint_entry_three.created_at = 26.days.ago


    complaint_entry_one.save
    complaint_entry_two.save
    complaint_entry_three.save

    range_from = 30.days.ago.to_s.gsub(" ", "+")
    range_to = 20.days.ago.to_s.gsub(" ", "+")

    get "/escalations/api/v1/escalations/webcat/complaints/complaint_report_stats?date_from=#{range_from}&date_to=#{range_to}", headers: { 'Token' => @auth_token }

    json_response = JSON.parse(JSON.parse(response.body))

    expect(json_response["count"]).to equal 3

  end


end
