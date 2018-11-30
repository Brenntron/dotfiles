require "rails_helper"

RSpec.describe "Resolution message templates", type: :request do
  let(:message_template) { FactoryBot.create(:rulehit_resolution_mailer_template) }
  let(:customer) { FactoryBot.create(:customer) }
  let(:dispute) { FactoryBot.create(:dispute) }
  let(:dispute_entry) { FactoryBot.create(:dispute_entry) }
  let(:rule_hit) { FactoryBot.create(:dispute_rule_hit) }


  it 'retrieves a template' do
    binding.pry
    message_template
    customer
    dispute
    dispute_entry
    rule_hit
    get '/escalations/webrep/resolution_message_templates/0'
    # get '/escalations/webrep/resolution_message_templates'

    # Correct path:
    # /escalations/api/v1/rulehit_resolution_mailer_templates/make_rulehit_mail/1004
    # binding.pry # Inspect this complete `response` object (find out wtf factorybot is actually making)
    expect(response.code).to eq('400')
  end


end
