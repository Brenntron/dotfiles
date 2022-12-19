FactoryBot.define do
  factory :dispute_entry do
    dispute_id      { 1 }
    uri             { 'talosintelligence.com' }
    entry_type      { 'URI/DOMAIN' }
    status          { 'NEW' }
    case_opened_at  { Time.now }
  end

  trait :with_preloader do
    dispute_entry_preload {  FactoryBot.create(:dispute_entry_preloader, dispute_entry_id: :dispute_entry.id)}
  end
end
