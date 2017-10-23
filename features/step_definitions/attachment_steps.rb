Given (/^an "(.*?)" attachment exists$/) do |attachment|
  @attachment = FactoryGirl.create(:attachment)
end

Given(/^an attachment exists and belongs to bug "(.*?)"/)  do |bug_id|
  attachment = FactoryGirl.create(:attachment)
  Bug.find(bug_id).attachments << attachment
end

Given(/^an attachment exists that belongs to bug "(.*?)" and alerts on rule "(.*?)"/) do |bug_id, rule_id|
  attachment = FactoryGirl.create(:attachment)
  Bug.find(bug_id).attachments << attachment

  rule = Rule.find(rule_id)
  FactoryGirl.create(:alert, rule_id: rule.id, attachment_id: attachment.id, test_group: 'pcap')
end

Then(/^I clean up attachments/) do
  Attachment.destroy_all
end

Then(/^the attachment with file name "(.*?)" summary should be saved as "(.*?)"/) do |file_name, summary|
  attachment = Attachment.find_by(file_name: file_name)
  attachment.file_name.should ==  attachment.summary
end