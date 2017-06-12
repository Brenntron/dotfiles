Given (/^a bug exists$/) do
  @bug = FactoryGirl.create(:bug)
end

Given(/^the following bugs exist:$/) do |bugs|
  bugs.hashes.each do |bug|
    FactoryGirl.create(:bug, bug)
  end
end

Given(/^the current user has the following bugs:$/) do |given_bugs|
  user = User.where(cvs_username: ENV['authenticate_cvs_username']).first || FactoryGirl.create(:current_user)
  given_bugs.hashes.each do |bug_attrs|
    FactoryGirl.create(:bug, bug_attrs.merge(user_id: user.id))
  end
end

Given(/^the current user has the following "(.*?)":$/) do |factory_name, given_bugs|
  user = User.where(cvs_username: ENV['authenticate_cvs_username']).first || FactoryGirl.create(:current_user)
  given_bugs.hashes.each do |bug_attrs|
    FactoryGirl.create(factory_name.to_sym, bug_attrs.merge(user_id: user.id))
  end
end

Given(/^I fill in selectized with "(.*?)"$/) do |value|
  find('div.selectize-input input', match: :first).set("#{value}")
  find('div.selectize-dropdown-content > div', match: :first).click
end

And(/^the selectize field contains the text "(.*?)"$/) do |text|
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

When(/^I send a GET request to "(.*)"$/) do |url|
  get(url)
end

When(/^I make an API request to bug "(.*?)"$/) do |id|
  get("/api/v1/bugs/#{id}.json")
end

Then(/^response should have bug_id "(.*?)"$/) do |id|
  target = JSON.parse(last_response.body)
  target[0]["id"].should eq(id)
end
