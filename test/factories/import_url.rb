FactoryBot.define do
  factory :import_url do
    jira_import_task
    submitted_url { Faker::Internet.url }
    domain { Faker::Internet.domain_name }
    bast_verdict { 'Parked' }
  end
end
