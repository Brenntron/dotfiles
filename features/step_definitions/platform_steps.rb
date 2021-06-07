Given(/^the following platforms exist:$/) do |platforms|
  platforms.hashes.each do |platform|
    FactoryBot.create(:platform, platform)
  end
end

Given(/^platforms with all traits exist$/) do
  FactoryBot.create(:platform)
  FactoryBot.create(:platform, :webrep)
  FactoryBot.create(:platform, :emailrep)
  FactoryBot.create(:platform, :webcat)
  FactoryBot.create(:platform, :filerep)
  FactoryBot.create(:platform, :inactive)
end
