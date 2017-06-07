FactoryGirl.define do
  factory :role do
    role 'analyst'

    factory :analyst_role do
      role 'analyst'
    end

    factory :committer_role do
      role 'committer'
    end
  end
end
