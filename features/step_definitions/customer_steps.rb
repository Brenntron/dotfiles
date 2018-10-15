Given(/^the following customers exist:$/) do |customers|
  customers.hashes.each do |customer|
    FactoryBot.create(:customer, customer)
  end
end

Given(/^the following customers exist with trait "(.*?)" exist:$/) do |trait_name, customers|
  customers.hashes.each do |customers_attrs|
    FactoryBot.create(:customer, trait_name.to_sym, customers_attrs)
  end
end