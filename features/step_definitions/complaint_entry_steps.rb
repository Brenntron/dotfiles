Given(/^the following complaint entries exist:$/) do |entries|
  entries.hashes.each do |entry|
    FactoryBot.create(:complaint_entry, entry)
  end
end
Given(/^a complaint entry with trait "(.*?)" exists$/) do| trait_name|
  FactoryBot.create(:complaint_entry,trait_name.to_sym)
end
Given(/^a new complaint entry with trait "(.*?)" exists$/) do| trait_name|
  FactoryBot.create(:complaint_entry,:new_entry,trait_name.to_sym)
end
Given(/^an assigned complaint entry with trait "(.*?)" exists$/) do| trait_name|
  FactoryBot.create(:complaint_entry,:assigned_entry,trait_name.to_sym)
end

Given(/^a complaint entry preload exists$/)  do
  FactoryBot.create(:complaint_entry_preload)
end
