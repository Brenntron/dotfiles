Given(/^the following dispute emails exist:$/) do |dispute_emails|
  dispute_emails.hashes.each do |dispute_email|
    FactoryBot.create(:dispute_email, dispute_email)
  end
end

And(/^row with email_id "(.*?)" should have class "(.*?)"$/) do |email_id, class_name|
  page.find(:xpath, "//tr[@email_id=#{email_id}]")[:class].include?(class_name)
end

And(/^I click on row with email_id "(.*?)"$/) do |email_id|
  page.first(:xpath, "//tr[@email_id=#{email_id}]/td").click
end

And(/^I fill in the reply textarea with "(.*?)"$/) do |text|
  text_area = first(:css, 'textarea.email-reply-body').native
  text_area.send_keys(text)
end
