FactoryBot.define do
  factory :jira_import_task do
    sequence(:issue_key) { |n| "SD-#{n}" }
    status { 'pending' }
    sequence(:result) { |n| "result-#{n}" }
    submitter { Faker::Name.name }
    issue_summary { 'These are URLS, pls add categories'}
    issue_description { 'URLs was imported by DOC team' }
    issue_status { 'Open' }
    issue_platform { 'Secure Platform' }
    issue_type { "Small Requests ≤ 50 URL" }
    sequence(:bast_task) { |n| n }
    imported_at { Time.now }

    trait :with_import_urls do
      after(:create) do |jira_import_task|
        create_list(:import_url, 3, jira_import_task: jira_import_task)
      end
    end
  end
end