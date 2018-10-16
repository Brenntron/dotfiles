FactoryBot.define do
  factory :customer do
    company         { FactoryBot.create(:company)}
    name            { "Bob Jones" }
    email           { "bob@bob.com" }
    phone           { "1234567890" }
  end
end