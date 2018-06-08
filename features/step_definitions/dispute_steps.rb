Given(/^the following disputes exist:$/) do |disputes|
  disputes.hashes.each do |dispute|
    FactoryGirl.create(:dispute, dispute)
  end
end