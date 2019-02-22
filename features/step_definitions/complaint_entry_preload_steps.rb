
require 'cucumber/rspec/doubles'

Given(/^complaint entry preload is stubbed$/) do
  ComplaintEntryPreload.stub(:generate_preload_from_complaint_entry)
end
