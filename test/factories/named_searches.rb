FactoryBot.define do
  factory :named_search do
    user_id     {User.first.id}
    name        {'Lab'}
  end
end
