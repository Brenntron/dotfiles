Given (/^a "(.*?)" rule category exists$/) do |category|
  @rule = FactoryGirl.create(:rule_category, category: category)
end

Given(/^the following rule categories exist:$/) do |categories|
  categories.hashes.each do |category|
    FactoryGirl.create(:rule_category, category)
  end
end
