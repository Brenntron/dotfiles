FactoryBot.define do
  factory :dispute_comment do
    dispute_id      { 1 }
    comment         { "this is a test comment" }
    user_id         { 1 }
    created_at      { Time.now }
  end
end