Given(/^the following complaints exist:$/) do |complaints|
  complaints.hashes.each do |complaint|
    FactoryBot.create(:complaint, complaint)
  end
end