FactoryBot.define do
  factory :company do
    name            { "Bobs Burgers" }
    initialize_with {Company.find_or_create_by(name:name)}

    factory :guest_company do
      name          { "Guest" }
      initialize_with {Company.find_or_create_by(name:name)}
    end

    factory :bogus_company do
      name          { "123r3f" }
    end
  end
end
