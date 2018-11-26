FactoryBot.define do
  factory :rulehit_resolution_mailer_template do
    mnemonic { 'dotq' }
    to { 'cisco@gmail.com' }
    cc { 'cisco@gmail.com' }
    subject { 'Cucumber' }
    body { 'This is a test body' }
  end
end
