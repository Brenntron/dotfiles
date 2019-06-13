FactoryBot.define do
  factory :file_rep_comment do
    comment                     {'Cucumber test'}
    file_reputation_dispute_id  {1}
    user_id                     {1}
  end
end