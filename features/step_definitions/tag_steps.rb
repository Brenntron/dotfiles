Given (/^a "(.*?)" tag exists$/) do |tag|
  @tag = FactoryBot.create(:tag)
end

Given(/^the following tags exist:$/) do |tags|
  tags.hashes.each do |tag|
    FactoryBot.create(:tag, tag)
  end
end