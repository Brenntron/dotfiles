Given(/^the following customers exist:$/) do |customers|
  customers.hashes.each do |customer|
    FactoryBot.create(:customer, customer)
  end
end

Given(/^Dispute Analyst customer exists$/) do
  FactoryBot.create(:dispute_analyst)
end