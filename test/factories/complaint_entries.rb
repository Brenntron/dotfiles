FactoryBot.define do
  factory :complaint_entry do
    complaint       {  FactoryBot.create(:complaint)}
    subdomain       { 'www' }
    domain          { 'testing.com' }
    path            { '/downloads' }
    wbrs_score      { 2 }
    url_primary_category {'test'}
    sbrs_score      { 10 }
    ip_address      { '1.1.1.1' }
    category        { 'bogus_category' }

    trait :important do
      is_important  { true }
    end
    trait :not_important do
      is_important  { false }
    end

    trait :new_entry do
      status        { 'NEW' }
      resolution    {''}
      user          { FactoryBot.create(:user,:vrt_incoming_user) }
    end
    trait :pending_entry do
      status        { 'PENDING' }
      resolution    { 'fixed' }
      user          { FactoryBot.create(:user) }
    end
    trait :assigned_entry do
      status        { 'ASSIGNED' }
      resolution    {''}
      user          {User.first}
    end
    trait :completed_entry do
      status        { 'COMPLETED' }
      resolution    { 'fixed' }
      user          { FactoryBot.create(:user)}
    end

  end
end

