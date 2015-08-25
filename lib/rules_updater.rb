#!/usr/bin/env ruby

require 'stomp'
require 'json'

# Make sure we run from the application root
Dir.chdir ENV['APP_ROOT']

# Limit the amount of memory used by a single client (300MB)
Process.setrlimit(:AS, 300 * 1024 * 1024)
stomp_options ={}
case RAILS.env
  when "production"
    stomp_options = {
        :hosts => [{ :login => "guest", :passcode => "guest", :host => 'mq.vrt.sourcefire.com', :port => 61613, :ssl => false }],
        :reliable => true,
    }
  when "staging"
    stomp_options = {
        :hosts => [{ :login => "guest", :passcode => "guest", :host => 'mqtest01.vrt.sourcefire.com', :port => 61613, :ssl => false }],
        :reliable => true,
    }
  when "development"
    stomp_options = {
        :hosts => [{ :login => "guest", :passcode => "guest", :host => 'localhost', :port => 61613, :ssl => false }],
        :reliable => true,
    }
end


# Create our stomp client
client = Stomp::Connection.new(stomp_options)

# This queue should only have work jobs for local rule runs
client.subscribe "/queue/RulesUI.Snort.Commit.Test.Reload", { :ack => :client }

while message = client.receive
	begin

		# Start by parsing the request
		request = JSON.parse(message.body)

		# We just need to run extras/update_rules
		if request['reload_so'] == true
			`extras/update_rules`
		else
			`extras/update_rules true`
		end

		# Finally let the server release this message
		client.ack(message.headers['message-id'])

	rescue JSON::ParserError => e
		puts e.inspect
	end
end
