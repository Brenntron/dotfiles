FactoryBot.define do
  factory :named_search_criterion do
    named_search_id         {1}
    field_name              {'status'}
    value                   {'NEW'}
  end
end
