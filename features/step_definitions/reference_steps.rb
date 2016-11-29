Given(/^the following references exist:$/) do |refs|
  refs.hashes.each do |ref|
    FactoryGirl.create(:reference, ref)
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

