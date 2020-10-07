Given(/^the following complaint_tags exist:$/) do |complaint_tags|
  complaint_tags.hashes.each do |complaint_tag|
    FactoryBot.create(:complaint_tag, complaint_tag)
  end
end

Given(/^I add a complaint_tag of id "(.*?)" to complaint of id "(.*?)"$/) do |complaint_tag_id, complaint_id|
  Complaint.find(complaint_id).complaint_tags << ComplaintTag.find(complaint_tag_id)
end