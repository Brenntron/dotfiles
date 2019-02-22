
require 'cucumber/rspec/doubles'

Given(/^WBRS top url is stubbed$/) do
  Wbrs::TopUrl.stub(:check_urls).and_return([])
end

Given(/^WBRS Prefix where is stubbed$/) do
  Wbrs::Prefix.stub(:where).and_return([])
end
