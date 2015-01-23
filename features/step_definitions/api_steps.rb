When(/^I send authenticated headers to the api request "(.*?)"/) do |url|
  page.driver.add_headers({:token => "12345"})
  visit(url)
end