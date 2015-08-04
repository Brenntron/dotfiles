#!/usr/bin/env ruby

require 'open3'
require 'stomp'
require 'sfbugzilla'
require 'json'
require 'tmpdir'
require 'tempfile'
require 'vrt/rule_test_api'
require 'base64'
require 'pry'

stomp_options = {
	:hosts => [
      { :login => "guest", :passcode => "guest", :host => 'mqtest01.vrt.sourcefire.com', :port => 61613, :ssl => false },
      { :login => "guest", :passcode => "guest", :host => 'localhost', :port => 61613, :ssl => false }
  ],
	:reliable => true,
  :closed_check => false
}
# Create our stomp client
client = Stomp::Connection.new(stomp_options)
client.subscribe "/queue/RulesUI.Snort.Run.Local.Test.Work", { :ack => :client }

while message = client.receive
  puts "We did some work. And now..."
  # Start by parsing the request
  request = JSON.parse(message.body)

  # Release the message early
  client.ack(message.headers['message-id'])
  sleep(2)
  puts "back to you."
  client.publish "/queue/RulesUI.Snort.Run.Local.Test.Result",
                 {
                     :ret_req   => request,
                     :message   => message.body,
                     :something => "Here is a messsage. We did some work."
                 }.to_json
end







