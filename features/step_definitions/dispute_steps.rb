Given(/^the following disputes exist:$/) do |disputes|
  FactoryBot.create(:company) unless Company.all.exists?
  FactoryBot.create(:customer) unless Customer.all.exists?
  FactoryBot.create(:user) unless User.all.exists?
  disputes.hashes.each do |dispute|
    FactoryBot.create(:dispute, dispute)
  end
end

