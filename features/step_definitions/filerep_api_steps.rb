require 'cucumber/rspec/doubles'

Given(/^ThreatGrid API call is stubbed$/) do
  Threatgrid::Search.stub(:query).and_return([])
end

Given(/^Reversing Labs certificates API call is stubbed$/) do
  FileReputationApi::ReversingLabs.stub(:certificates).and_return(nil)
end

Given(/^ReversingLabs API call is stubbed$/) do
  FileReputationApi::ReversingLabs.stub(:sha256_lookup).and_return(nil)
end

Given (/^Sandbox API call is stubbed$/) do
  FileReputationApi::Sandbox.stub(:score).and_return(nil)
end

Given (/^AMP API call is stubbed$/) do
  FileReputationApi::Detection.stub(:get_bulk).and_return(nil)
end

Given (/^Sample Zoo API call is stubbed$/) do
  FileReputationApi::SampleZoo.stub(:sha256_lookup).and_return(nil)
end

Given (/^ReversingLabs Creation Data API call is stubbed$/) do
  FileReputationApi::ReversingLabs.stub(:get_creation_data).and_return(file_size: 1188, sample_type: 'Bogus')
end