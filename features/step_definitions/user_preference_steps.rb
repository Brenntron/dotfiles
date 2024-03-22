Given(/^I create WebRep Entries Per Page UserPreference$/) do
  FactoryBot.create(:user_preference, :webrep_entries_per_page_preference)
end
Given(/^I create WebRep Sort Order UserPreference$/) do
  FactoryBot.create(:user_preference, :webrep_sort_order_preference)
end
Given(/^I create WebRep Current Page UserPreference$/) do
  FactoryBot.create(:user_preference, :webrep_current_page_preference)
end
Given(/^I show all webcat index columns$/) do
  FactoryBot.create(:user_preference, :webcat_show_all_columns)
end