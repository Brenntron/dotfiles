FactoryBot.define do
  factory :complaint_entry do
    complaint       {  FactoryBot.create(:complaint)}
    subdomain       { 'www' }
    domain          { 'google.com' }
    path            { '/about' }
    wbrs_score      { 2 }
    url_primary_category {''}
    sbrs_score      { 10 }
    ip_address      { '8.8.8.8' }
    category        { 'bogus_category' }

    trait :high_telemetry do
      status               { 'PENDING' }
      url_primary_category {'Arts'}
    end
    trait :important do
      is_important  { true }
    end
    trait :not_important do
      is_important  { false }
    end

    trait :new_entry do
      status        { 'NEW' }
      resolution    { '' }
      user          { FactoryBot.create(:vrt_incoming_user) }
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
    trait :assigned_closed_entry do
      status        { 'COMPLETED' }
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

