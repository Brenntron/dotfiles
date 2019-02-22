
require 'cucumber/rspec/doubles'

Given(/^bugzilla rest api always saves$/) do
  bug_proxy = BugzillaRest::BugProxy.new({id: 10101}, api_key: nil, token:nil)
  bug_proxy.stub(:save!).and_return(true)

  BugzillaRest::BugProxy.stub(:new).and_return(bug_proxy)
end
