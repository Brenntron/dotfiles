Then(/^two research entries exists$/) do
  expect( all('.research-table-row').count ).to eq(2)
end

Then(/^multiple research entries exist$/) do
  expect( all('.research-table-row').count ).to be > (1)
end

Then(/wl\/bl result number "(.*?)" should have content "(.*?)"/) do |result_number, content|
  find("table.bfrp-table tr.result-no-#{result_number} .wlbl-table-result")
end

Then(/wl\/bl result number "(.*?)" should not have content "(.*?)"/) do |result_number, content|
  element = find("table.bfrp-table tr.result-no-#{result_number} .wlbl-table-result")
  raise "content found when it should not have been found" if element.has_content?(content)
end

Then(/quick lookup entry "(.*?)" column number "(.*?)" should have content "(.*?)"/) do |type, number, content|
  page.evaluate_script("$('tr .col-#{type}')[#{number}].textContent.indexOf('#{content}') !== -1")
end

Then(/ toggle checkbox of quick lookup entry row number "(.*?)"/) do |number|
  page.evaluate_script("$('tr input')[#{number}].checked = !$('tr input')[#{number}].checked")
end