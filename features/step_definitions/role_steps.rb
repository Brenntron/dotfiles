Given(/^the following roles exist:$/) do |roles|
  roles.hashes.each do |role|
    FactoryBot.create(:role, role)
  end
end

Given(/^the following org_subsets exist:$/) do |org_subsets|
  org_subsets.hashes.each do |org_subset|
    FactoryBot.create(:org_subset, org_subset)
  end
end