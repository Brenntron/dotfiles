FactoryBot.define do
  factory :dispute_email do
    dispute_id      { 1 }
    from            { 'customer@customer.com' }
    to              { 'cisco@cisco.com' }
    subject         { 'This is the subject of the email' }
    body            { 'This is the body of the email' }
    status          { 'unread' }
    created_at      { Time.now }
  end
end
