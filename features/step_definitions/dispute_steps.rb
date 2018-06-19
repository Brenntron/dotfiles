Given(/^the following disputes exist:$/) do |disputes|
  disputes.hashes.each do |dispute|
    FactoryBot.create(:dispute, dispute)
  end
end