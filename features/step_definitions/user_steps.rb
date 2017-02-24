Given (/^a "(.*?)" user exists$/) do |role|
  @user = FactoryGirl.create(:user)
end

Given(/^the following users exist$/) do |users|
  users.hashes.each do |user|
    FactoryGirl.create(:user, user)
  end
end

Given(/^a user with commit permission exists and is logged in$/) do
  @user = FactoryGirl.create(:user, confirmed: true, committer: true)
  visit root_path()
end

Given(/^a user with role "(.*?)" exists and is logged in$/) do |role|
  @user = FactoryGirl.create(:user, confirmed: true)
  @role = Role.create(role: role)
  @user.roles << @role
  visit root_path()
end

Given(/^a manager exists and is logged in$/) do
  @user = FactoryGirl.create(:user, confirmed: true)
  @role = Role.create(role: 'manager')
  @user.roles << @role
  visit root_path(api_key: "h93hq@hwo9%@ah!jsh")
end

Given(/^a user exists$/) do
  @user = FactoryGirl.create(:user, confirmed: true)
end

Then(/^I visit the root url$/) do
  visit root_path()
end
