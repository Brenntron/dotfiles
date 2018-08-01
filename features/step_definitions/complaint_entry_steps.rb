Given(/^the following complaint entries exist:$/) do |entries|
  entries.hashes.each do |entry|
    FactoryBot.create(:complaint_entry, entry)
  end
end
Given(/^a complaint entry with trait "(.*?)" exists$/) do| trait_name|
  FactoryBot.create(:complaint_entry,trait_name.to_sym)
end
