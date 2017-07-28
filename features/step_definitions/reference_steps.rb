Given(/^the following references exist:$/) do |refs|
  refs.hashes.each do |ref|
    FactoryGirl.create(:reference, ref)
  end
end
Given(/^the following references exist belonging to bug "(.*?)":$/) do |bug_id, references|
  bug = Bug.where(id: bug_id).first
  references.hashes.each do |ref_attrs|
    bug.references << FactoryGirl.create(:reference, ref_attrs)
  end
end
Given(/^the following references exist belonging to rule with sid "(.*?)":$/) do |rule_sid, references|
  rule = Rule.where(sid: rule_sid).first
  references.hashes.each do |ref_attrs|
    rule.references << FactoryGirl.create(:reference, ref_attrs)
  end
end

Given(/^a reference type exists$/) do
  FactoryGirl.create(:reference_type)
end

Given(/^the following reference types exist:$/) do |refs|
  refs.hashes.each do |ref|
    FactoryGirl.create(:reference_type, ref)
  end
end

And(/^reference with id "(.*?)" has exploit with id "(.*?)"$/) do |ref_id, expl_id|
  Reference.where(id: ref_id).first.exploits << Exploit.where(id:expl_id).first
end

