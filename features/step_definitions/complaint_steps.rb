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
    # FactoryBot.create(:complaint_entry, complaint_entry_id: entry.id, resolution: "FIXED", case_resolved_at: Time.now)
  end
end

Given(/^I go ?to a "(.*?)" report surrounding the current year$/) do |report_type|
  # `report_type` is always either 'complaint_entry' or 'resolution'
  low_date = Time.now.year - 1
  high_date = Time.now.year + 1
  url = "/escalations/webcat/reports/#{report_type}?utf8=1&report%5Bdate_from%5D=#{low_date}-01-01&report%5Bdate_to%5D=#{high_date}-01-01&report%5Bcustomer_name%5D=&commit=Report"
  visit (url)
end