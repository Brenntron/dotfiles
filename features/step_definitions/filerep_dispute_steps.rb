Then (/^a FileRep Ticket should have been created$/) do
  expect(FileReputationDispute.count).to eq(1)
end

Then (/^a FileRep Ticket should have a TG score$/) do
  expect(FileReputationDispute.first.threatgrid_score).not_to eq(nil)
end

Then (/^a FileRep Ticket should have a Sandbox score$/) do
  expect(FileReputationDispute.first.sandbox_score).not_to eq(nil)
end

Then (/^a FileRep Ticket should have a RL score$/) do
  expect(FileReputationDispute.first.reversing_labs_score).not_to eq(nil)
end

Then (/^that FileRep Ticket should have a SHA256 of "(.*?)"$/) do |sha256|
  expect(FileReputationDispute.first.sha256_hash).to eq(sha256)
end

Then (/^that FileRep Ticket should have an assignee of current user$/) do
  expect(FileReputationDispute.first.user_id).to eq(1)
end

Then (/^that FileRep Ticket should have a suggested disposition of "(.*?)"$/) do |disposition_suggested|
  expect(FileReputationDispute.first.disposition_suggested).to eq(disposition_suggested)
end

Given(/^the following FileRep disputes exist:$/) do |disputes|
  disputes.hashes.each do |dispute_attrs|
    FactoryBot.create(:file_reputation_dispute, dispute_attrs)
  end
end

Given(/^A FileRep Dispute with trait "(.*?)" exists$/) do |trait_name|
  FactoryBot.create(:file_reputation_dispute,trait_name.to_sym)
end

Given(/^FileRep Dispute has the appropriate 'resolution_comment' for auto-resolved entries$/) do
  expect(FileReputationDispute.first.resolution_comment).to eq(FileReputationDispute::RESOLUTION_AUTORESOLVED_COMMENT)
  expect(FileReputationDispute.first.resolution_comment).not_to eq(nil)
end

Then(/^no FileRep dispute comments exists$/) do
  expect(FileRepComment.count).to eq(0)
end

Given(/^A FileRep Dispute comment with trait "(.*?)" exists$/) do |trait_name|
  FactoryBot.create(:file_rep_comment,trait_name.to_sym)
end

