Then (/^a FileRep Ticket should have been created$/) do
  expect(FileReputationDispute.count).to eq(1)
end

Given(/^the following FileRep disputes exist:$/) do |disputes|
  disputes.hashes.each do |dispute_attrs|
    FactoryBot.create(:file_reputation_dispute, dispute_attrs)
  end
end

Given(/^A FileRep Dispute with trait "(.*?)" exists$/) do |trait_name|
  FactoryBot.create(:file_reputation_dispute,trait_name.to_sym)
end