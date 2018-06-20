Given(/^the following email templates exist:$/) do |email_templates|
  email_templates.hashes.each do |email_template|
    FactoryBot.create(:email_template, email_template)
  end
end