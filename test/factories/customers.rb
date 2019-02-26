FactoryBot.define do
  factory :customer do
    association     :company
    name            { "Bob Jones" }
    email           { "bob@bob.com" }
    phone           { "1234567890" }
    initialize_with {Customer.first_or_create(email:email)}
  end
end