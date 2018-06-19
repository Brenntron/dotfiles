Given(/^the following roles exist:$/) do |roles|
  roles.hashes.each do |role|
    FactoryBot.create(:role, role)
  end
end