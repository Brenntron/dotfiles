Given (/^a "(.*?)" rule category exists$/) do |role|
  @rule = FactoryGirl.create(:rule_category)
end

Given(/^the following rule categories exist:$/) do |categories|
  categories.hashes.each do |category|
    FactoryGirl.create(:rule_category, category)
  end
end
