Given (/^a "(.*?)" tag exists$/) do |tag|
  @tag = FactoryGirl.create(:tag)
end

Given(/^the following tags exist:$/) do |tags|
  tags.hashes.each do |tag|
    FactoryGirl.create(:tag, tag)
  end
end