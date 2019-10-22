Given(/^the following companies exist:$/) do |companies|
  companies.hashes.each do |company|
    FactoryBot.create(:company, company)
  end
end

Given(/^a guest company exists$/) do
  FactoryBot.create(:guest_company)
end