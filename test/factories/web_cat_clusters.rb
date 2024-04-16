FactoryBot.define do
  factory :cluster, class: 'WebCatCluster' do
    domain { 'www.cisco.com' }

    trait :ngfw do
      platform { create(:platform, public_name: 'FirePower', internal_name: 'NGFW') }
      cluster_type { 'ngfw' }
    end

    trait :umbrella do
      platform { create(:platform, public_name: 'Umbrella', internal_name: 'Umbrella') }
      cluster_type { 'umbrella' }
    end

    trait :meraki do
      platform { create(:platform, public_name: 'Meraki MX', internal_name: 'Meraki') }
      cluster_type { 'meraki' }
    end
  end
end
