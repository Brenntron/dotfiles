Given(/^the following SDR disputes exist:$/) do |disputes|
  FactoryBot.create(:customer) unless Customer.all.exists?
  FactoryBot.create(:user) unless User.all.exists?
  FactoryBot.create(:platform) unless Platform.all.exists?
  disputes.hashes.each do |dispute_attrs|
    dispute = FactoryBot.create(:sender_domain_reputation_dispute, dispute_attrs.reverse_merge(user_id: User.first.id, customer_id: Customer.first.id, platform_id: Platform.first.id))
  end
end

Given(/^the following SDR dispute attachments exist:$/) do |disputes|
  FactoryBot.create(:sender_domain_reputation_dispute) unless SenderDomainReputationDispute.all.exists?
  disputes.hashes.each do |dispute_attrs|
    dispute = FactoryBot.create(:sender_domain_reputation_dispute_attachment, dispute_attrs.reverse_merge(sender_domain_reputation_dispute_id: SenderDomainReputationDispute.first.id))
  end
end
