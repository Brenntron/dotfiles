Given (/^a "(.*?)" user exists$/) do |role|
  @user = FactoryGirl.create(:user)
end

Given(/^the following users exist:$/) do |users|
  users.hashes.each do |user|
    FactoryGirl.create(:user, user)
  end
end

