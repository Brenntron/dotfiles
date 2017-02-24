Given(/^the following roles exist:$/) do |roles|
  roles.hashes.each do |role|
    FactoryGirl.create(:role, role)
  end
end