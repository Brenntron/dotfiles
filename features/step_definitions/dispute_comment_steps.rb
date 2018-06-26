Given(/^the following dispute comments exist:$/) do |dispute_comments|
  dispute_comments.hashes.each do |dispute_comment|
    FactoryBot.create(:dispute_comment, dispute_comment)
  end
end

And(/^I click the note with text "(.*?)"$/) do |text|
  find('.note-block', :text => text).click
end


And(/^I click the delete button of the first comment$/) do
  first(".note-delete-button").click
end

And(/^I fill a content-editable field "(.*?)" with "(.*?)"$/) do |class_name, content|
  find(class_name).base.send_keys(content)
end