FactoryBot.define do
  factory :sender_domain_reputation_dispute do
    customer_id           { 1 }
    user_id               { 1 }
    status                { SenderDomainReputationDispute::STATUS_NEW }
    platform_id           { 1 }
    sender_domain_entry   { 'test@google.com' }
    suggested_disposition { 'false negative' }
    source                { 'TI Webform' }
    submitter_type        { 'Customer' }
  end
end
