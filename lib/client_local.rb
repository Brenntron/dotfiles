#!/usr/bin/env ruby

require 'open3'
require 'stomp'
require 'sfbugzilla'
require 'json'
require 'tmpdir'
require 'tempfile'
require 'base64'
require 'pry'
puts "test1"
stomp_options = {
	:hosts => [
      { :login => "guest", :passcode => "guest", :host => 'mqtest01.vrt.sourcefire.com', :port => 8161, :ssl => true },
      { :login => "guest", :passcode => "guest", :host => 'mqtest01.vrt.sourcefire.com', :port => 8161, :ssl => false }
  ],
	:reliable => true
}

# Create the xmlrpc instance for updating later
xmlrpc = Bugzilla::XMLRPC.new('bugzilla.vrt.sourcefire.com')
puts "test2"
# Create our stomp client
client = Stomp::Connection.new(stomp_options)
puts "test3"
client.subscribe "/queue/RulesUI.Snort.Run.Local.Test.Work", { :ack => :client }
puts "test4"

while message = client.receive
  puts "We did some work. And now..."
  # Start by parsing the request
  request = JSON.parse(message.body)

  # Release the message early
  client.ack(message.headers['message-id'])
  binding.pry
  sleep(2)
  puts "back to you."
  client.publish "/queue/RulesUI.Snort.Run.Local.Test.Result",
                 {
                     :ret_req   => request,
                     :message   => message.body,
                     :something => "Here is a messsage. We did some work."
                 }.to_json
end







