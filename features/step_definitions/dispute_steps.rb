Given(/^the following disputes exist:$/) do |disputes|
  FactoryBot.create(:customer) unless Customer.all.exists?
  FactoryBot.create(:user) unless User.all.exists?
  disputes.hashes.each do |dispute_attrs|
    FactoryBot.create(:dispute, dispute_attrs)
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


