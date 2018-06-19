Given (/^a bug exists$/) do
  @bug = FactoryBot.create(:bug)
end

Given(/^the following bugs exist:$/) do |bugs|
  bugs.hashes.each do |bug|
    FactoryBot.create(:bug, bug)
  end
end

Given(/^the following "(.*?)" bugs with trait "(.*?)" exist:$/) do |factory_name, trait_name, bug_table|
  bug_table.hashes.each do |bug_attrs|
    FactoryBot.create(factory_name.to_sym, trait_name.to_sym, bug_attrs)
  end
end

Given(/^the current user has the following bugs:$/) do |given_bugs|
  user = User.where(cvs_username: ENV['authenticate_cvs_username']).first || FactoryBot.create(:current_user)
  given_bugs.hashes.each do |bug_attrs|
    FactoryBot.create(:bug, bug_attrs.merge(user_id: user.id))
  end
end

Given(/^the current user has the following "(.*?)":$/) do |factory_name, given_bugs|
  user = User.where(cvs_username: ENV['authenticate_cvs_username']).first || FactoryBot.create(:current_user)
  given_bugs.hashes.each do |bug_attrs|
    FactoryBot.create(factory_name.to_sym, bug_attrs.merge(user_id: user.id))
  end
end

Given(/^I fill in selectized with "(.*?)"$/) do |value|
  find('div.selectize-input input', match: :first).set("#{value}")
  find('div.selectize-dropdown-content > div', match: :first).click
end

And(/^the selectize field with id "(.*?)" contains the text "(.*?)"$/) do |element, text|
  find("##{element}", visible: :all).value[0].should == "#{text}"
end

And(/^the selectize field contains the text "(.*?)"$/) do | text|
  find(:xpath, "//div[contains(@class, '#{'selectize-input'}')]").text.should == "#{text}"
end

And(/^I change the "(.*?)" of bug number "(.*?)" to "(.*?)"$/) do |method, id, status|
  # binding.pry
  # page.driver.put, "/api/v1/bugs/#{id}", { :params => {method: status} }
end

Given(/^the bug "(.*?)" has tag "(.*?)"$/) do |bug_id, tag |
  @bug = Bug.find(bug_id)
  @tag = Tag.find_or_create_by(name: tag)
  @bug.tags << @tag
end

And(/^bugs_rules with rule_id of "(.*?)" and "bug_id" of "(.*?)" should have the in_summary flag$/) do |rule_id, bug_id|
  association = BugsRule.where(rule_id: rule_id, bug_id: bug_id).first
  association.in_summary.should eq(1)
end

And(/^bugs_rules with rule_id of "(.*?)" and "bug_id" of "(.*?)" should not have the in_summary flag$/) do |rule_id, bug_id|
  association = BugsRule.where(rule_id: rule_id, bug_id: bug_id).first
  association.in_summary.should eq(0)
end

When(/^I make a GET request to "(.*)"$/) do |url|
  get(url)
end

When(/^I make an API request to bug "(.*?)"$/) do |id|
  get("/api/v1/bugs/#{id}.json")
end

Then(/^response should have bug_id "(.*?)"$/) do |id|
  target = JSON.parse(last_response.body)
  target[0]["id"].should eq(id)
end

Then(/^I relate (.*?) to (.*?) with block$/) do |from_id, to_id|
  bug1 = Bug.find(from_id)
  bug2 = Bug.find(to_id)

  bug1.snort_research_bugs << bug2
  bug1.snort_blocker_bugs << bug2

end

And(/^I should have (.*?) saved searches for user (.*?)$/) do |num_searches, user_id|
  user = User.find(user_id)
  user.saved_searches.size.should eq(num_searches.to_i)
end

