FactoryBot.define do
  factory :company do
    name            { "Bobs Burgers" }
    initialize_with {Company.first_or_create(name:name)}

    factory :guest_company do
      name          { "Guest" }
    end
  end
end
