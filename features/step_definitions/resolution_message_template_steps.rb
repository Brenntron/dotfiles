Given(/^a resolution message template exists$/) do
  FactoryBot.create(:resolution_message_template)
end

Given(/^the following resolution message templates exist:$/) do |templates|
  templates.hashes.each do |template_attrs|
    FactoryBot.create(:resolution_message_template, template_attrs)
  end
end