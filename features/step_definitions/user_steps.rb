Given (/^a "(.*?)" user exists$/) do |role|
  @user = FactoryGirl.create(:fake_user)
  @role = Role.create(role: role)
  @user.roles << @role
end

Given(/^the following users exist$/) do |users|
  users.hashes.each do |user|
    FactoryGirl.create(:user, user)
  end
end

Given(/^a user with commit permission exists and is logged in$/) do
  @user = FactoryGirl.create(:current_user, confirmed: true)
  @role = Role.create(role: 'committer')
  @user.roles << @role
  visit root_path
end

Given(/^a user with role "(.*?)" exists and is logged in$/) do |role|
  @user = FactoryGirl.create(:current_user, confirmed: true)
  @role = Role.create(role: role)
  @user.roles << @role
  visit root_path
end

Given(/^a user with id "(.*?)" has a parent with id "(.*?)"$/) do |user_id, parent_id|
  @user = User.find(user_id)
  @user.update(parent_id: parent_id)
end

Given(/^a user with id "(.*?)" has a role of "(.*?)"$/) do |user_id, role|
  @user = User.find(user_id)
  @user.roles << Role.where(role: role).first
end

Given(/^a manager exists and is logged in$/) do
  @user = FactoryGirl.create(:current_user, confirmed: true)
  @role = Role.create(role: 'manager')
  @user.roles << @role
  visit root_path(api_key: "h93hq@hwo9%@ah!jsh")
end

Given(/^current user exists$/) do
  @user = FactoryGirl.create(:current_user, confirmed: true)
end

Then(/^I visit the root url$/) do
  visit root_path
end

Then(/^I should see a user search form$/) do
  find(:xpath, "//form[@action='/users/results'][@method='get']") &&
      find(:xpath, "//form[@action='/users/results']/input[@name='user[search][name]']") &&
      find(:xpath, "//form[@action='/users/results']/input[@type='submit'][@value='search']")
end

Then(/^I see a (\w*) new form$/) do |resources_name|
  find(:xpath, "//form[@action='/#{resources_name}'][@method='post']")
end

Then(/^I see a user_searches form$/) do
  find(:xpath, "//form[@action='/user_searches'][@method='get']")
end

When(/^I create a user search for name "(.*)"$/) do |name|
  # page.driver.submit :get, "/user_searches", :name => name
  visit "/user_searches"
end

Then(/^I see a user_searches result for name "(.*)"$/) do |name|
  find(:xpath, "//td[text()='#{name}']")
end

Then(/^I do not see a user_searches result for name "(.*)"$/) do |name|
  page.should have_no_selector(:xpath, "//td[contains(text(), '#{name}')]")
end

Then(/^I should see could not find user "(.*)" flash massage$/) do |user_id|
  find(:xpath, "//div[contains(concat(' ', normalize-space(@class), ' '), ' alert ')][contains(text(), \"Could not find user '#{user_id}'\")]")
end


