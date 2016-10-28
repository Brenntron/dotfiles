Given (/^a "(.*?)" user exists$/) do |role|
  @user = FactoryGirl.create(:user)
end

Given(/^the following users exist$/) do |users|
  users.hashes.each do |user|
    FactoryGirl.create(:user, user)
  end
end

Given(/^a user exists and is logged in$/) do
  @user = FactoryGirl.create(:user, confirmed: true)
  visit root_path()
end

Given(/^a user exists$/) do
  @user = FactoryGirl.create(:user, confirmed: true)
end

Then(/^I visit the root url$/) do
  visit root_path()
end
