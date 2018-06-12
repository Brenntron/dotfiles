FactoryGirl.define do
  factory :role do
    role 'analyst'

    org_subset_id { OrgSubset.find_or_create_by(name: 'everyone').id }

    factory :analyst_role do
      role 'analyst'
    end

    factory :committer_role do
      role 'committer'
    end
  end
end
