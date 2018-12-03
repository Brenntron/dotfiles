require "rails_helper"
include Warden::Test::Helpers # This maybe should be done in Rspec.config?

RSpec.describe "Resolution message templates", type: :request do
  let(:message_template) { FactoryBot.create(:rulehit_resolution_mailer_template) }
  let(:customer) { FactoryBot.create(:customer, id: 1) }
  let(:dispute) { FactoryBot.create(:dispute, customer_id: 1, id: 1) }
  let(:dispute_entry) { FactoryBot.create(:dispute_entry, dispute_id: 1) }
  let(:rule_hit) { FactoryBot.create(:dispute_rule_hit) }
  let(:current_user) { FactoryBot.create(:current_user) }

  it 'retrieves a template' do
    message_template
    customer
    dispute
    dispute_entry
    rule_hit
    login_as(current_user, :scope => :user)

    get '/escalations/api/v1/rulehit_resolution_mailer_templates/make_rulehit_mail/0'
    expect(response.code).to eq('200')
  end

  it 'retrieves an ad-hoc template' do
    customer
    dispute
    login_as(current_user, :scope => :user)

    post '/escalations/api/v1/rulehit_resolution_mailer_templates/make_adhoc_rulehit_mail', headers: { 'Content-Type': 'application/json' },
         params: {:rulehit_name => message_template.mnemonic, :url => dispute_entry.uri}.to_json
    expect(response.code).to eq('201')
  end

end
