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

Given(/^the following dispute_entry_preloads exist:$/) do |dispute_entry_preloads|
  dispute_entry_preloads.hashes.each do |dispute_entry_preloads_attrs|
    FactoryBot.create(:dispute_entry_preload, dispute_entry_preloads_attrs)
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

Then(/^clean up wlbl and remove all wlbl entries on "(.*?)"$/) do |url|
  @user = User.first
  Wbrs::ManualWlbl.adjust_urls_from_params({:urls=>[url], "trgt_list"=>[], "note"=>""}, username: @user.cvs_username)
end

Then(/^clean up reptool and remove all reptool entries on "(.*?)"$/) do |url|
  @user = User.first
  reptool_params = {}
  reptool_params["action"] = "EXPIRED"
  reptool_params["entries"] = [url]
  RepApi::Blacklist.adjust_from_params(reptool_params, username: @user.cvs_username)
end
Given(/^an empty dispute exists$/) do
  FactoryBot.create(:customer) unless Customer.all.exists?
  dispute = FactoryBot.create(:dispute, {user_id: nil, subject: nil, problem_summary: nil, case_opened_at: nil, submission_type: nil})
  dispute.assign_attributes(customer_id: nil)
  dispute.save!(validate: false)
end

Given(/^the user is logged into bugzilla$/) do
  BugzillaRest::Session.any_instance.stub(:logged_in?).and_return(true)
end
