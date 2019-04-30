require 'cucumber/rspec/doubles'

Given(/^ThreatGrid API call is stubbed$/) do
  Threatgrid::Search.stub(:query).and_return([])
end

Given(/^TiCloud API call is stubbed$/) do
  Ticloud::FileAnalysis.stub(:certificates).and_return(nil)
end

Given(/^ReversingLabs API call is stubbed$/) do
  FileReputationApi::ReversingLabs.stub(:sha256_lookup).and_return(nil)
end

Given (/^Sandbox API call is stubbed$/) do
  FileReputationApi::Sandbox.stub(:score).and_return(nil)
end