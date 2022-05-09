Given(/^the following SDR disputes exist:$/) do |disputes|
  FactoryBot.create(:customer) unless Customer.all.exists?
  FactoryBot.create(:user) unless User.all.exists?
  disputes.hashes.each do |dispute_attrs|
    dispute = FactoryBot.create(:sender_domain_reputation_dispute, dispute_attrs.reverse_merge(user_id: User.first.id, customer_id: Customer.first.id))
  end
end
