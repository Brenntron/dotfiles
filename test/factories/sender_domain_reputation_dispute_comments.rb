FactoryBot.define do
  factory :sender_domain_reputation_dispute_comment do
    sender_domain_reputation_dispute_id { 1 }
    comment                             { "this is a test comment" }
    user_id                             { 1 }
    created_at                          { Time.now }
  end
end
