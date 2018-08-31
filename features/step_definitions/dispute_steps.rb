Given(/^the following disputes exist:$/) do |disputes|
  FactoryBot.create(:customer) unless Customer.all.exists?
  FactoryBot.create(:user) unless User.all.exists?
  disputes.hashes.each do |dispute|
    FactoryBot.create(:dispute, dispute)
  end
end


Given(/^the following dispute_entries exist:$/) do |dispute_entries|
  FactoryBot.create(:customer) unless Customer.all.exists?
  FactoryBot.create(:user) unless User.all.exists?
  dispute_entries.hashes.each do |dispute_entry|
    FactoryBot.create(:dispute, dispute_entry)
  end
end


Given(/^the following disputes exist and have entries:$/) do |disputes|
  FactoryBot.create(:customer) unless Customer.all.exists?
  FactoryBot.create(:user) unless User.all.exists?
  disputes.hashes.each do |dispute|
    dispute = FactoryBot.create(:dispute, dispute)
    entry = FactoryBot.create(:dispute_entry, dispute_id: dispute.id)
    FactoryBot.create(:dispute_entry_preload, dispute_entry_id: entry.id)
  end
end



