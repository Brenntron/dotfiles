FactoryBot.define do
  factory :note do
    comment         { 'Just an average comment' }
    note_type       { 'research' }
    author          { 'nicherbe@cisco.com' }
    bug_id          { 145359 }
  end
end
