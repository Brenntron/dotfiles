Given(/^I goto "(.*?)"$/) do |url|
  visit (url)
end

Given(/^I fill in "(.*?)" with "(.*?)"$/) do |field_label, value|
  fill_in field_label, :with => value
end

When(/^I click "(.*?)"$/) do |target|
  click_on(target)
end

When(/^I check "(.*?)"$/) do |target|
  check(target)
end
When(/^I uncheck "(.*?)"$/) do |target|
  uncheck(target)
end

When(/^I choose "(.*?)"$/) do |target|
  choose(target)
end

When(/^I click link "(.*?)"$/) do |link| #id or link name
  click_link(link)
end

When(/^I click \(within\) "(.*?)" within "(.*?)"$/) do |target, context|
  within(context) do
    page.click_link(target)
  end
end

When(/^I click the link "(.*?)" in row "(.*?)" of the table with class "(.*?)"$/) do |target, row_number, table_class|
  page.find(:xpath, "//*[contains(@class, '#{table_class}')]//tr[#{row_number}]").click_link(target)
end

When(/^I click button "(.*?)"$/) do |button|
  click_button(button)
end

When(/^I "(.*?)" the url "(.*?)"$/) do |method, url|
  case method
  when "GET"
    page.driver.submit :get, url, { :params => {} }
  when "DELETE"
    page.driver.submit :delete, url, { :params => {} }
  when "POST"
    page.driver.submit :post, url, { :params => {} }
  end
end

When(/^I "(.*?)" the url "(.*?)" with "(.*?)" data$/) do |method, url, model|
  case model
  when "Release"
    data = FactoryGirl.create(:release)
  end

  case method
  when "POST"
    page.driver.submit :post, url, { :params => {release: data.attributes} }
  end
end

When(/^I PUT "(.*?)" with "(.*?)" data; column: "(.*?)" value: "(.*?)"$/) do |url, model, attribute, value|
  page.driver.submit :put, url, {"#{model}".to_sym => {"#{attribute}".to_sym => "#{value}"} } 
end

Given(/^I click "(.*?)" within the "(.*?)" row$/) do |target, row_number|
  page.find(:xpath, "//table//tr[#{row_number}]").click_link(target)
end

Then(/^Element with content "(.*?)" should have class "(.*?)"$/) do |content,class_name|
  find(:xpath, "//div[contains(@class, '#{class_name}')][contains(text(), '#{content}')]")
end

Then(/^Element with class "(.*?)" should have content "(.*?)"$/) do |class_name, content|
  find(:xpath, "//div[contains(@class, '#{class_name}')][contains(text(), '#{content}')]")
end

Then(/^Element with id "(.*?)" should have content "(.*?)"$/) do |content,id_name|
  find(:xpath, "//div[contains(@id, '#{id_name}')][contains(text(), '#{content}')]")
end

Then(/^I should see the "(.*?)" radio checked$/) do |radio_class|
  radio = page.find(:xpath, "//input[@type='radio' and @class='#{radio_class}']")
  raise "Radio with class #{radio_class} not checked" if radio.checked?.blank?
end

Given(/^I click an image button in table "(.*?)" at row "(.*?)" and col "(.*?)" with class name "(.*?)"$/) do |table, row, column,class_name|
page.find(:xpath, "//table[#{table}]//tr[#{row}]//td[#{column}]//*[contains(@class, '#{class_name}')]").click
end

Given(/^I toggle bootstrap-switch in table "(.*?)" at row "(.*?)" and col "(.*?)"$/) do |table, row, column|
  page.find(:xpath, "//table[#{table}]//tr[#{row}]//td[#{column}]//*[contains(@class, 'switch-mini')]").click
end

Then(/^Element in table "(.*?)" at row "(.*?)" and col "(.*?)" has class "(.*?)"$/) do |table, row, column, class_name|
  page.find(:xpath, "//table[#{table}]//tr[#{row}]//td[#{column}]//*[contains(@class, '#{class_name}')]")
end

Given(/^I wait for index$/) do
  sleep 10
end

Given(/^I wait for "(.*?)" seconds$/) do |seconds|
  sleep seconds.to_i
end

When(/^I select "(.*?)" from "(.*?)"$/) do |option, select|
  if option == "next year"
    option = (Time.now + 1.year).strftime("%Y")
  end
  select(option, :from => select)
end

Then(/^I should see "(.*?)"$/) do |content|
  raise "content not found" unless page.has_content?(content)
end

Then(/^I should see either "(.*?)" or "(.*?)"$/) do |content1, content2|
  raise "content not found" unless ( page.has_content?(content1) || page.has_content?(content2) )
end

Then(/^I should not see "(.*?)"/) do |content|
  raise "content found when it should not have been found" if page.has_content?(content)
end

Then(/^I should see "(.*?)" in the current url$/) do |content|
  raise "content not found" if page.current_url.match(content).nil?
end

Then(/^I should see content "(.*?)" within "(.*?)"$/) do |content, target|
  within(target) do
    page.has_content?(content)
  end
end

Then(/^I should not see content "(.*?)" within "(.*?)"$/) do |content, target|
  within(target) do
    !page.has_content?(content)
  end
end

Then(/^the "(.*?)" field should be "(.*?)"$/) do |name, value| 
  raise "Field \"#{name}\" is not \"#{value}\"" unless find_field(name).value == value
end

Then(/^"(.*?)" should be visible$/) do |target| #target is #id or .class
  page.find(target).visible?
end

Then(/^I should be on "(.*?)"$/) do |path|
  raise "current_path is not \"#{path}\":  current_path = #{current_path} " unless current_path == path
end

Then(/^I should receive a "(.*?)" status$/) do |status_code|
  raise "recieved status code #{page.status_code.to_s}. Expected status code #{status_code.to_s}" unless page.status_code.to_s == status_code.to_s
end

Then(/^response header "(.*?)" should be "(.*?)"$/) do |header_key,header_value|
  raise "response header #{header_key} = #{page.response_headers[header_key]}. Expected #{header_value}" if page.response_headers[header_key] != header_value
end

Then(/^show me the page$/) do
  save_and_open_page
end

Then(/^take a screenshot$/) do 
  page.save_screenshot('/tmp/screenshot.png', :full => true)
  `open /tmp/screenshot.png`
end

Then(/^take a before screenshot$/) do 
  page.save_screenshot('/tmp/before_screenshot.png', :full => true)
  `open /tmp/before_screenshot.png`
end

Then(/^take an after screenshot$/) do 
  page.save_screenshot('/tmp/after_screenshot.png', :full => true)
  `open /tmp/after_screenshot.png`
end

Then(/^I do some debugging$/) do
  #insert debug lines here
  # page.driver.debug  #you need @debug and @javascript for this to work
  binding.pry
end

Then(/^open inspector$/) do
  page.driver.debug
end
