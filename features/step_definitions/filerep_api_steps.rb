require 'cucumber/rspec/doubles'

Given(/^ThreatGrid API call is stubbed$/) do
  allow(Threatgrid::Search).to receive(:query) {{}}
end

Given(/^ThreatGrid API data is stubbed$/) do
  allow(Threatgrid::Search).to receive(:data) {{}}
end

Given(/^Reversing Labs certificates API call is stubbed$/) do
  allow(FileReputationApi::ReversingLabs).to receive(:certificates) {nil}
end

Given(/^ReversingLabs API call is stubbed$/) do
  allow(FileReputationApi::ReversingLabs).to receive(:sha256_lookup) {nil}
end

Given(/^The file is not in ReversingLabs$/) do
  allow(FileReputationApi::ReversingLabs).to receive(:lookup) {OpenStruct.new(raw_json: "{\"error\":\"Not in RL\"}")}
end

Given(/^Sandbox API call is stubbed$/) do
  allow(FileReputationApi::Sandbox).to receive(:score) {nil}
end

Given(/^The sample does not exist in the sandbox$/) do
  allow(FileReputationApi::Sandbox).to receive(:sample_exists) {false}
end

Given(/^AMP API call is stubbed and returns a disposition of, "(.*?)"$/) do |disposition|
  book = FileReputationApi::Detection.new
  book.disposition = disposition

  allow(FileReputationApi::Detection).to receive(:get_bulk) {book}
end

Given(/^AMP API call is stubbed$/) do
  allow(FileReputationApi::Detection).to receive(:get_bulk) {nil}
end

Given(/^Sample Zoo API call is stubbed$/) do
  allow(FileReputationApi::SampleZoo).to receive(:sha256_lookup) {nil}
end

Given(/^The file is not in the sample zoo$/) do
  allow(FileReputationApi::SampleZoo).to receive(:sha256_lookup) {{in_zoo: false}}
end

Given(/^ReversingLabs Creation Data API call is stubbed$/) do
  allow(FileReputationApi::ReversingLabs).to receive(:get_creation_data) { {file_size: 1188, sample_type: 'Bogus'} }
end
