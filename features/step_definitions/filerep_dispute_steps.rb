Then (/^a FileRep Ticket should have been created$/) do
  expect(FileReputationDispute.count).to eq(1)
end