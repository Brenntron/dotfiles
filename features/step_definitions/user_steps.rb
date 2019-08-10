Given (/^a "(.*?)" user exists$/) do |role|
  @user = FactoryBot.create(:fake_user)
  @role = FactoryBot.create(:role, role: role)
  @user.roles << @role
end

Given(/^the following users exist$/) do |users|
  users.hashes.each do |user|
    FactoryBot.create(:user, user)
  end
end

Given(/^a user with commit permission exists and is logged in$/) do
  @user = FactoryBot.create(:current_user, confirmed: true)
  @role = FactoryBot.create(:role, role: 'committer')
  @user.roles << @role
  sign_in_user
end

Given(/^an admin user with role "(.*?)" exists and is logged in$/) do |role|
  @user = FactoryBot.create(:current_user, confirmed: true)
  @user.roles << FactoryBot.create(:role, role: 'admin')
  @user.roles << FactoryBot.create(:role, role: role)
  sign_in_user
end

Given(/^a user with role "(.*?)" exists and is logged in$/) do |role|
  @user = FactoryBot.create(:current_user, confirmed: true)
  @user.roles << FactoryBot.create(:role, role: role)
  sign_in_user
end

Given(/^vrtincoming exists$/) do
  FactoryBot.create(:vrt_incoming_user)
end

Given(/^a user with role "(.*?)" exists with cvs_username, "(.*?)", exists and is logged in$/) do |role, username|
  @user = FactoryBot.create(:current_user, confirmed: true, cvs_username: username)
  @user.roles << FactoryBot.create(:role, role: role)
  # sign_in_user
  @user.update(bugzilla_api_key: Rails.configuration.bugzilla_api_key)
end

Given(/^a user with id "(.*?)" has a role "(.*?)" and is logged in$/) do |user_id, role|
  @role = FactoryBot.create(:role, role: role)
  @user = FactoryBot.create(:current_user, confirmed: true, id: user_id)
  @user.roles << @role
  sign_in_user
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
  @user = FactoryBot.create(:current_user, confirmed: true)
  @role = FactoryBot.create(:role, role: 'manager')
  @user.roles << @role
  sign_in_user
end

Given(/^current user exists$/) do
  @user = FactoryBot.create(:current_user, confirmed: true)
end

def fill_in_login_form
  fill_in "username", :with => ENV['Bugzilla_login']
  fill_in "password", :with => ENV['Bugzilla_secret']
end

def sign_in_user
  current_user = User.where(cvs_username: ENV['authenticate_cvs_username']).first
  current_user.update(bugzilla_api_key: Rails.configuration.bugzilla_api_key)
  # case
  # when current_user.roles.where(role: 'webcat user').exists?
  #   visit escalations_webcat_complaints_path
  # when current_user.roles.where(role: 'webrep user').exists?
  #   visit escalations_webrep_disputes_path
  # end
  # click_on('user-settings-dropdown-button')
  # fill_in_login_form
  # click_on('top_banner_bugzilla_login_button')
  # sleep 3
end
Given (/^the user signs in$/) do
  sign_in_user
end

Then(/^I visit the root url$/) do
  visit root_path
end

Then(/^I should see a user search form$/) do
  find(:xpath, "//form[@action='/escalations/users/results'][@method='get']") &&
      find(:xpath, "//form[@action='/escalations/users/results']/input[@name='user[search][name]']") &&
      find(:xpath, "//form[@action='/escalations/users/results']/input[@type='submit'][@value='search']")
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
  find(:xpath, "//div[contains(@class, 'alert')][text()[contains(., \"Could not find user '#{user_id}'\")]]")
end

Then(/^current user not in database$/) do
  user_attrs = FactoryBot.attributes_for(:current_user)
  user = User.where(cvs_username: user_attrs[:cvs_username]).first
  user.should be_nil
end

Then(/^current user should be in database$/) do
  user_attrs = FactoryBot.attributes_for(:current_user)
  user = User.where(cvs_username: user_attrs[:cvs_username]).first
  user.should_not be_nil
end

Given(/^current user is a bug user$/) do
  user_attrs = FactoryBot.attributes_for(:current_user)
  user = User.create_by_email(user_attrs[:email])
  user.save
end

Given(/^I should see my username$/) do
  user_attrs = FactoryBot.attributes_for(:current_user)
  username  = User.where(cvs_username: user_attrs[:cvs_username]).first.cvs_username
  if !page.has_content?(username)
    raise "content not found when it should have been found"
  end
end

Given(/^I should not see my username$/) do
  user_attrs = FactoryBot.attributes_for(:current_user)
  username  = User.where(cvs_username: user_attrs[:cvs_username]).first.cvs_username
  if page.has_content?(username)
    raise "content found when it should not have been found"
  end
end

Then (/^current user should not have kerberos login$/) do
  user_attrs = FactoryBot.attributes_for(:current_user)
  User.where(cvs_username: user_attrs[:cvs_username]).count.should == 1
  user = User.where(cvs_username: user_attrs[:cvs_username]).first
  user.kerberos_login.should == nil
end

Then(/^current user should have kerberos login$/) do
  user_attrs = FactoryBot.attributes_for(:current_user)
  User.where(cvs_username: user_attrs[:cvs_username]).count.should == 1
  user = User.where(cvs_username: user_attrs[:cvs_username]).first
  user.kerberos_login.should == user_attrs[:kerberos_login]
end

Then(/^I should see user, "(.*?)", in element "(.*?)"$/) do |username, element|
  within element do
    expect(page).to have_content(username)
  end
end

Given(/^a user with role "(.*?)" exists within org subset "(.*?)" and is logged in$/) do |role, org_subset|
  @user = FactoryBot.create(:current_user, confirmed: true)
  FactoryBot.create(:org_subset, name: org_subset)
  @user.roles << FactoryBot.create(:role, role: role, org_subset_id: 1)
  sign_in_user
end
