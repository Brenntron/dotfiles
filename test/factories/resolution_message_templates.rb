FactoryBot.define do
  factory :resolution_message_template do
    name { 'Templar' }
    description { 'Axe' }
    body { "This is a test." }
    status { 1 }
    resolution_type { 'FIXED' }
    creator_id { User.first.id }
    editor_id { User.first.id }
  end

  trait :webcat_template do
    ticket_type { 'WebCategoryDispute' }
  end
end
