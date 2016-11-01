Given (/^a "(.*?)" rule exists$/) do |role|
  @rule = FactoryGirl.create(:rule)
end

Given(/^the following rules exist:$/) do |rules|
  rules.hashes.each do |rule|
    FactoryGirl.create(:rule, rule)
  end
end

Then(/^I click the "(.*?)" tab$/) do |value|
  tab = "#{value}".downcase
  find(:xpath, "//ul[@id='bug_tab']/li/a[@data-target='##{tab}-tab']").click()
end

Then(/^"(.*?)" should be listed first$/) do |value|
  find_field('rule_category_id').all('option').collect(&:text)[1].should == value
end
