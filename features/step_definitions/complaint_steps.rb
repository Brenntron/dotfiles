Given(/^the following complaints exist:$/) do |complaints|
  complaints.hashes.each do |complaint|
    FactoryBot.create(:complaint, complaint)
  end
end
Given(/^a complaint with trait "(.*?)" exists$/) do| trait_name|
  FactoryBot.create(:complaint,trait_name.to_sym)
end