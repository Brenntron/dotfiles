FactoryBot.define do
  factory :customer do
    association     :company
    name            { "Bob Jones" }
    email           { "bob@bob.com" }
    phone           { "1234567890" }
    initialize_with {Customer.find_or_create_by(email:email)}
    factory :dispute_analyst do
      name            { "Dispute Analyst" }
    end
  end

  factory :guest_customer do
    association     :company
    name            { "Guest" }
    email           { "guest@gst.com" }
    phone           { "18005548378" }
    initialize_with {Customer.find_or_create_by(email:email)}
  end
end