FactoryBot.define do
  factory :dispute do
    customer_id     { 1 }
    user_id         { 1 }
    status          { 'new' }
    subject         { 'We have a dispute' }
    problem_summary { 'This is the summary of my dispute' }
    case_opened_at  { Time.now - 1.day }
    submission_type { 'ew' }
  end
end
