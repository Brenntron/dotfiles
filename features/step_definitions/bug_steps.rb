Given (/^a bug exists$/) do
  @bug = FactoryGirl.create(:bug)
end

Given(/^the following bugs exist:$/) do |bugs|
  bugs.hashes.each do |bug|
    FactoryGirl.create(:bug, bug)
  end
end

Given(/^I fill in selectized with "(.*?)"$/) do |value|
  find('div.selectize-input input', match: :first).set("#{value}")
  find('div.selectize-dropdown-content > div', match: :first).click
end

And(/^the selectize field contains the text "(.*?)"$/) do |text|
  find(:xpath, "//div[contains(@class, '#{'selectize-input'}')]").text.should == "#{text}"
end