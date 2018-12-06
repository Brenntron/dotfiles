Given /^pending/i do
  pending
end

Given(/^I go ?to "(.*?)"$/) do |url|
  visit (url)
end

Given(/^I fill in "(.*?)" with "(.*?)"$/) do |field_label, value|
  fill_in field_label, :with => value
end

Given(/^I fill in "(.*?)" with today's date"$/) do |field_label|
  time = Time.now.strftime("%Y-%m-%d")
  fill_in field_label, :with => time

end

When(/^I click "(.*?)"$/) do |target|
    begin
      click_on(target)
    rescue Capybara::ElementNotFound => e
      page.find("#{target}").click
    end
end

When(/^I click through "(.*?)" and accept confirmation$/) do |target|
  accept_confirm do
    page.find("#{target}").click
  end
end

When (/^I click label "(.*?)"$/) do |target|
  find("label[for=#{target}]").click
end

Then(/^I cannot click "(.*?)"$/) do |target|
  begin
    raise "Clicked on #{target} when should not have been able to" if click_on(target)
  rescue Capybara::ElementNotFound => e
  end
end
When(/^I toggle checkbox "(.*?)"$/) do |target|
  page.find(target).click
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

When(/^I click a table row$/) do
  page.find(:css, ".not-shown").click()
end

Given(/^I upload "(.*?)" from_button "(.*?)"$/) do |filename, type|
  attach_file("#{type}", "#{Rails.root}/lib/data/#{filename}")
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

Then(/^I hide the element with class "(.*?)"$/) do |element|
  page.execute_script("$('.#{element}').hide()")
end

When(/^I click button "(.*?)"$/) do |button|
  click_button(button)
end

When(/^I click button with class "(.*?)"$/) do |button_class|
  click_on(class: button_class)
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
    data = FactoryBot.create(:release)
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

Then(/^Element with id "(.*?)" should have content "(.*?)"$/) do |id_name, content|
  find(:xpath, "//div[contains(@id, '#{id_name}')][contains(text(), '#{content}')]")
end

Then(/^I should see the "(.*?)" radio checked$/) do |radio_class|
  radio = page.find(:xpath, "//input[@type='radio' and @class='#{radio_class}']")
  raise "Radio with class #{radio_class} not checked" if radio.checked?.blank?
end

Then(/^I should see the "(.*?)" checkbox checked$/) do |checkbox_class|
  page.find(checkbox_class).should be_checked
end

Then(/^I should see the "(.*?)" checkbox unchecked$/) do |checkbox_class|
  page.find(checkbox_class).should_not be_checked
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

When /^I wait for the ajax request to finish$/ do
  start_time = Time.now
  page.evaluate_script('jQuery.isReady&&jQuery.active==0').class.should_not eql(String) until page.evaluate_script('jQuery.isReady&&jQuery.active==0') or (start_time + 5.seconds) < Time.now do
    sleep 1
  end
end

When(/^select "(.*?)" from "(.*?)" within "(.*?)"$/) do |option, select, context|
  within(context) do
    select(option, :from => select)
  end
end

When(/^click button "(.*?)" within "(.*?)"$/) do |button, context|
  within(context) do
    click_button(button)
  end
end

When(/^the "(.*?)" option from "(.*?)" is disabled$/) do |option, select|
  select(option, :from => select).disabled? == true
end

When(/^the "(.*?)" option from "(.*?)" is not disabled$/) do |option, select|
  select(option, :from => select).disabled? == false
end

When(/^I select "(.*?)" from "(.*?)"$/) do |option, select|
  if option == "next year"
    option = (Time.now + 1.year).strftime("%Y")
  end
  select(option, :from => select)
end
When(/^I can not select "(.*?)" from "(.*?)"$/) do |option, select|
  this_is_true = false
  begin
    select(option, :from => select)
  rescue Capybara::ElementNotFound => e
    if e.message.match(/Unable to find option/)
      this_is_true = true
    else
      raise "content found but this is the incorrect message"
    end
  end
  raise "content found when it should not have been found" unless this_is_true == true
end

Then(/^I should see "(.*?)"$/) do |content|
  # binding.pry
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

Then(/^I should see content "(.*?)" within first element of class "(.*?)"$/) do |content, target|
  within(target, match: :first) do
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

Then(/^"(.*?)" should not be visible$/) do |target| #target is #id or .class
  expect(page).not_to have_selector(target)
end

Then(/^I should see button with class "(.*?)"$/) do |element|
  page.should have_selector(:xpath, "//button[contains(@class, '#{element}')]")
end

Then(/^I should see table header with id "(.*?)"$/) do |element|
  page.should have_selector(:xpath, "//th[contains(@id, '#{element}')]")
end

Then(/^I should not see button with class "(.*?)"$/) do |element|
  page.should have_no_selector(:xpath, "//button[contains(@class, '#{element}')]")
end

Then(/^I should see link with class "(.*?)"$/) do |element|
  page.should have_selector(:xpath, "//a[contains(@class, '#{element}')]")
end

Then(/^I should not see link with class "(.*?)"$/) do |element|
  page.should have_no_selector(:xpath, "//a[contains(@class, '#{element}')]")
end

Then(/^I should see div element with class "(.*?)"$/) do |element|
  page.should have_selector(:xpath, "//div[contains(@class, '#{element}')]")
end

Then(/^I should not see div element with class "(.*?)"$/) do |element|
  page.should have_no_selector(:xpath, "//div[contains(@class, '#{element}')]")
end

Then(/^the textarea with id "(.*?)" should contain "(.*?)"$/) do |id, content|
  page.find(:xpath, "//textarea[@id='#{id}']").text.should == content
end

Then(/^the textarea with id "(.*?)" should have a value of "(.*?)"$/) do |id, content|
  page.find(:xpath, "//textarea[@id='#{id}']").value.should == content
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

Then(/^I click the link with data-target "(.*?)"$/) do |target|
  find("a[data-target='#{target}']").click
end

Then(/^I click the span with data-target "(.*?)"$/) do |target|
  find("span[data-target='#{target}']").click
end

And(/^"(.*?)" should be in the "(.*?)" dropdown list$/) do |value, field|
  find_field(field).all('option').collect(&:text).include?(value).should == true
end

And(/^"(.*?)" should not be in the "(.*?)" dropdown list$/) do |value, field|
  find_field(field).all('option').collect(&:text).include?(value).should == false
end

And(/^"(.*?)" should be selected in the "(.*?)" dropdown$/) do |value, field|
  expect(page).to have_select(field, selected: value)
end

Then(/^show me the page$/) do
  save_and_open_page
end
Then(/^take a photo/)do
  save_and_open_screenshot
end

Then(/^I search for bug id "(.*?)"$/) do |value|
  find('#bug_id').set(value)
  page.execute_script("$('#search_form').submit()")
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

And(/^I resize the browser to "(.*?)" X "(.*?)"$/) do |x,y|
  Capybara.page.driver.browser.resize(x,y)
end

Then(/^open inspector$/) do
  page.driver.debug
end

Then(/^Expect date in element "(.*?)" to equal today's date$/) do |element|
  within element do
    t = Time.now
    expect(page).to have_content(t.strftime("%Y-%m-%d"))
  end
end

Then(/^I trigger-click "(.*?)"$/) do |target|
  find(target).trigger('click')
end

Then(/^I see "(.*?)" in element "(.*?)"/) do |content, element|
  within element do
    expect(page).to have_content(content)
  end
end

Then /I click "(.*?)" and switch to the new window/ do |target|
  page.switch_to_window(page.window_opened_by{find(target).trigger('click')})
end

Then (/^I should receive a file of type "(.*?)"/) do |type|
  result = page.response_headers['Content-Type'].should == type
end