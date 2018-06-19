FactoryBot.define do
  factory :dispute do
    status 'new'
    subject 'We have a dispute'
    problem_summary 'This is the summary of my dispute'
    case_opened_at Time.now
  end
end