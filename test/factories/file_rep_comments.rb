FactoryBot.define do
  factory :file_rep_comment do
    file_reputation_dispute_id      { 1 }
    comment         { "this is a test comment" }
    user_id         { 1 }
    created_at      { Time.now }
  end

  trait :new do
    file_reputation_dispute_id      { 1 }
    comment         { "Testing, 1-2-3" }
    user_id         { 1 }
    created_at      { Time.now }
  end
end