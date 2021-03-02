FactoryBot.define do
  factory :cluster_assignment do
    trait :expired do
      created_at { (ClusterAssignment::EXPIRED_TIMEOUT + 30).minutes.ago }
    end
  end
end
