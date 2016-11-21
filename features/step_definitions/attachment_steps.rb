Given (/^an "(.*?)" attachment exists$/) do |attachment|
  @attachment = FactoryGirl.create(:attachment)
end

Given(/^an attachment exists and belongs to bug "(.*?)"/)  do |bug_id|
  attachment = FactoryGirl.create(:attachment)
  Bug.find(bug_id).attachments << attachment
end

Then(/^I clean up attachments/) do
  Attachment.destroy_all
end