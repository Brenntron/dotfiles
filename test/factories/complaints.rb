FactoryBot.define do
  factory :complaint do
    channel         { 'some channel' }
    description     { 'Description for testing' }
    added_through   { 'testing interface' }
    customer        { FactoryBot.create(:customer)}

    trait :new_complaint do
      status        { 'NEW' }
      resolution    { '' }
    end

    trait :active_complaint do
      status        { 'ACTIVE' }
      resolution    { '' }
    end

    trait :completed_complaint do
      status        { 'COMPLETED' }
      resolution    { 'fixed' }
    end

  end
end
