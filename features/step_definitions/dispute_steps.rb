Given(/^the following disputes exist:$/) do |disputes|
  FactoryBot.create(:customer) unless Customer.all.exists?
  FactoryBot.create(:user) unless User.all.exists?
  disputes.hashes.each do |dispute_attrs|
    FactoryBot.create(:dispute, dispute_attrs)
  end
end

Given(/^the following unassigned disputes exist:$/) do |disputes|
  FactoryBot.create(:customer) unless Customer.all.exists?
  FactoryBot.create(:user) unless User.all.exists?
  FactoryBot.create(:user, cvs_username: "vrtincom", cec_username: "vrtincom", email: "vrt-incoming@sourcefire.com")
  disputes.hashes.each do |dispute_attrs|
    FactoryBot.create(:dispute, dispute_attrs.reverse_merge(user_id: User.where(cvs_username: "vrtincom").first.id))
  end
end



Given(/^the following dispute_entries exist:$/) do |dispute_entries|
  FactoryBot.create(:customer) unless Customer.all.exists?
  FactoryBot.create(:user) unless User.all.exists?

  dispute_entries.hashes.each do |dispute_entry_attrs|
    FactoryBot.create(:dispute_entry, dispute_entry_attrs)
  end
end


Given(/^the following disputes exist and have entries:$/) do |disputes|
  FactoryBot.create(:customer) unless Customer.all.exists?
  FactoryBot.create(:user) unless User.all.exists?
  disputes.hashes.each do |dispute_attrs|
    dispute = FactoryBot.create(:dispute, dispute_attrs.reverse_merge(user_id: User.first.id, customer_id: Customer.first.id))
    entry = FactoryBot.create(:dispute_entry, dispute_id: dispute.id)
    FactoryBot.create(:dispute_entry_preload, dispute_entry_id: entry.id)
  end
end

Then(/^check if dispute id, "(.*?)", has a related_id of "(.*?)"$/) do |dispute_id, related_id|
  expect((Dispute.where(id: 1)).first.related_id).to eq(2)
end

Given(/^the following disputes exist and have entries without preloads:$/) do |disputes|
  FactoryBot.create(:customer) unless Customer.all.exists?
  FactoryBot.create(:user) unless User.all.exists?
  disputes.hashes.each do |dispute_attrs|
    dispute = FactoryBot.create(:dispute, dispute_attrs.reverse_merge(user_id: User.first.id, customer_id: Customer.first.id))
    FactoryBot.create(:dispute_entry, dispute_id: dispute.id)
  end
end

Given(/^a dispute exists and is related to disputes with ID, "(.*?)":$/) do |related_id|
  FactoryBot.create(:customer) unless Customer.all.exists?
  FactoryBot.create(:user) unless User.all.exists?
  FactoryBot.create(:dispute, related_id: related_id, resolution: Dispute::DUPLICATE)
end

Then(/^the Entry preload with id "(.*?)" should exist$/) do |id|
  expect(DisputeEntryPreload.where(id: id)).to exist
end

Given(/^a dispute entry with trait "(.*?)" exists$/) do |trait_name|
  FactoryBot.create(:dispute_entry,trait_name.to_sym)
end

Given(/^a Dispute RuleHit exists with name, "(.*?)", and RuleType of "(.*?)"/) do |name, rule_type|
  FactoryBot.create(:dispute_rule_hit, name: name, rule_type: rule_type)
end

Given(/^a RuleHit Resolution Mailer template exists with mnemonic, "(.*?)"/) do |mnemonic|
  FactoryBot.create(:rulehit_resolution_mailer_template, mnemonic: mnemonic)
end

Given(/^a named search with the name, "(.*?)" exists/) do |name|
  FactoryBot.create(:named_search, name: name)
end

Given(/^a named search criteria exists with field_name: "(.*?)" and value: "(.*?)"/) do |field_name, value|
  FactoryBot.create(:named_search_criterion, field_name: field_name, value: value)
end

Given(/^I add a test user to current user's team/) do
  FactoryBot.create(:user, cvs_username: 'teammate', id: 2)
  User.find(2).move_to_child_of(User.find(1))
end
  
Given (/^Dispute entry should have a status of, "(.*?)"/) do |status|
  expect(Dispute.first.priority).to eq(status)
end
