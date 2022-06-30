FactoryBot.define do
  factory :umbrella_cluster do
    platform { create(:platform, public_name: 'Umbrella') }
  end
end
