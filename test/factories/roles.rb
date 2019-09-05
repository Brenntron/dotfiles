FactoryBot.define do
  factory :role do
    role            { 'analyst' }

    org_subset_id { OrgSubset.find_or_create_by(name: 'everyone').id }

    factory :analyst_role do
      role          { 'analyst' }
    end

    factory :committer_role do
      role          { 'committer' }
    end

    factory :file_rep_role do
      role          { 'filerep user' }
    end

    factory :web_cat_role do
      role          { 'webcat user' }
    end
  end
end
