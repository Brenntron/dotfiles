Given(/^the following email templates exist:$/) do |email_templates|
  email_templates.hashes.each do |email_template|
    FactoryBot.create(:email_template, email_template)
  end
end

Given(/^the following SDR email templates exist:$/) do |email_templates|
  email_templates.hashes.each do |email_template|
    FactoryBot.create(:sender_domain_reputation_email_template, email_template)
  end
end
