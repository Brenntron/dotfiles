FactoryBot.define do
  factory :company do
    name            { "Bobs Burgers" }

    factory :guest_company do
      name          { "Guest" }
    end
  end
end
