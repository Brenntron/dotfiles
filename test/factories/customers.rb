FactoryBot.define do
  factory :customer do
    company         { FactoryBot.create(:company)}
    name            { "Bob Jones" }
    email           { "bob@bob.com" }
    phone           { "1234567890" }
  end
end

FactoryBot.define do
  trait :dogfish_company do
    company         { FactoryBot.create(:company, name:'Dogfish')}
    name            { "Bob Dylan" }
    email           { "bob@bob.com" }
    phone           { "1234567890" }
  end
end