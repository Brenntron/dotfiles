Given(/^the following complaints exist:$/) do |complaints|
  complaints.hashes.each do |complaint|
    FactoryBot.create(:complaint, complaint)
  end
end
Given(/^a complaint with trait "(.*?)" exists$/) do| trait_name|
  FactoryBot.create(:complaint,trait_name.to_sym)
end

Given(/^the following complaints exist and have entries resolved today:$/) do |complaints|
  FactoryBot.create(:customer) unless Customer.all.exists?
  FactoryBot.create(:user) unless User.all.exists?
  complaints.hashes.each do |complaint_attrs|
    complaint = FactoryBot.create(:complaint, complaint_attrs.reverse_merge(customer_id: Customer.first.id))
    FactoryBot.create(:complaint_entry, complaint_id: complaint.id, resolution: "FIXED", case_resolved_at: Time.now, user_id: User.first.id)
  end
end

Given(/^the following complaints exist and have unresolved entries:$/) do |complaints|
  FactoryBot.create(:customer) unless Customer.all.exists?
  FactoryBot.create(:user) unless User.all.exists?
  complaints.hashes.each do |complaint_attrs|
    complaint = FactoryBot.create(:complaint, complaint_attrs.reverse_merge(customer_id: Customer.first.id))
    FactoryBot.create(:complaint_entry, complaint_id: complaint.id)
  end
end

Given(/^I go ?to a "(.*?)" report surrounding the current year$/) do |report_type|
  # `report_type` is always either 'complaint_entry' or 'resolution'
  low_date = Time.now.year - 1
  high_date = Time.now.year + 1
  url = "/escalations/webcat/reports/#{report_type}?utf8=1&report%5Bdate_from%5D=#{low_date}-01-01&report%5Bdate_to%5D=#{high_date}-01-01&report%5Bcustomer_name%5D=&commit=Report"
  visit (url)
end

Given(/^the following complaint entry with id: "(.*?)" has a resolution of: "(.*?)"$/) do |id, resolution|
  expect(ComplaintEntry.find(id).resolution).to eq(resolution)
end

Given(/^the following complaint entry with id: "(.*?)" has a status of: "(.*?)"$/) do |id, status|
  expect(ComplaintEntry.find(id).status).to eq(status)
end

Given(/^the following complaint entry with id: "(.*?)" has a internal comment of: "(.*?)"$/) do |id, internal_comment|
  expect(ComplaintEntry.find(id).internal_comment).to eq(internal_comment)
end

Given(/^the following complaint entry with id: "(.*?)" has a resolution comment of: "(.*?)"$/) do |id, resolution_comment|
  expect(ComplaintEntry.find(id).resolution_comment).to eq(resolution_comment)
end