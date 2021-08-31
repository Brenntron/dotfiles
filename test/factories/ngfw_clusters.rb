FactoryBot.define do
  factory :ngfw_cluster do
    platform { FactoryBot.create(:platform, public_name: 'NGFW') }
    traffic_hits { 0 }
  end
end
