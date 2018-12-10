
require 'cucumber/rspec/doubles'

Given(/^successful "(.*)" PeakeBridge post message is stubbed$/) do |class_name|
  response = double('Net::HTTPResponse', code: 200, body: 'The more windows you open, the cooler it gets.')

  conn = double(class_name)
  conn.stub(:post).and_return(response)

  peake_bridge_klass = class_name.constantize
  peake_bridge_klass.stub(:new).and_return(conn)
end

Given(/^successful PeakeBridge poll is stubbed$/) do
  success = double('Net::HTTPResponse', code: 200, body: 'The more windows you open, the cooler it gets.')

  ::Bridge::DirectRequest.stub(:poll).and_return(success)
end

Given(/^failing "(.*)" PeakeBridge post message is stubbed$/) do |class_name|
  response = double('Net::HTTPResponse', code: 500, body: 'Can\'t even')

  conn = double(class_name)
  conn.stub(:post).and_return(response)

  peake_bridge_klass = class_name.constantize
  peake_bridge_klass.stub(:new).and_return(conn)
end
