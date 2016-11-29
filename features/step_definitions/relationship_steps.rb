Given (/^a "(.*?)" relationship exists$/) do |role|
  @relationship = FactoryGirl.create(:relationship)
end

Given(/^the following relationships exist:$/) do |relationships|
  relationships.hashes.each do |relationship|
    FactoryGirl.create(:relationship, relationship)
  end
end

And(/^"(.*?)" should be in the dropdown list$/) do |value|
  find_field('relationship_team_member_id').all('option').collect(&:text).include?(value).should == true
end

And(/^"(.*?)" should not be in the dropdown list$/) do |value|
  find_field('relationship_team_member_id').all('option').collect(&:text).include?(value).should == false
end