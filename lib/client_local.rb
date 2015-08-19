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

stomp_options = {}
case RAILS.env
  when "production"
    puts "stomp in production"
    stomp_options = {
        :hosts => [{ :login => "guest", :passcode => "guest", :host => 'mq.vrt.sourcefire.com', :port => 61613, :ssl => false }],
        :reliable => true,  :closed_check => false
    }
  when "staging"
    puts "stomp in staging"
    stomp_options = {
        :hosts => [{ :login => "guest", :passcode => "guest", :host => 'mqtest01.vrt.sourcefire.com', :port => 61613, :ssl => false }],
        :reliable => true,  :closed_check => false
    }
  when "development"
    puts "stomp in development"
    stomp_options = {
        :hosts => [{ :login => "guest", :passcode => "guest", :host => 'localhost', :port => 61613, :ssl => false }],
        :reliable => true,  :closed_check => false
    }
end


# Create our stomp client
client = Stomp::Connection.new(stomp_options)
client.subscribe "/queue/RulesUI.Snort.Run.Local.Test.Work", { :ack => :client }


# Create the xmlrpc instance for updating later
# xmlrpc = Bugzilla::XMLRPC.new('bugzilla.vrt.sourcefire.com')

# Create our stomp client
client = Stomp::Connection.new(stomp_options)

# This queue should only have work jobs for All rule runs
client.subscribe "/queue/RulesUI.Snort.Run.All.Work", { :ack => :client }

# Initialize the API
RuleTestAPI.init('https://ruleapitest.vrt.sourcefire.com')

puts "test"
# Find the engine we should be using for these rules
engine_type = EngineType.where(:name => 'Persistent').first
puts "test1"
snort_configuration = SnortConfiguration.where(:name => 'Open Source').first
puts "test2"
rule_configuration = RuleConfiguration.where(:name => 'All Rules').first
puts "test3"

# Make sure everything was found
raise Exception.new("Unable to find Persistent engine type") if engine_type.nil?
raise Exception.new("Unable to find Open Source snort configuration") if snort_configuration.nil?
raise Exception.new("Unable to find All Rules configuration") if rule_configuration.nil?

engine = Engine.where(
    :engine_type_id => engine_type.id,
    :snort_configuration_id => snort_configuration.id,
    :rule_configuration_id => rule_configuration.id).first
raise Exception.new("Unable to find the Persistent All Rules Open Source engine") if engine.nil?

 while message = client.receive
  puts "We did some work. And now..."
  # Start by parsing the request
  request = JSON.parse(message.body)

  job_failed = false
  job_information = "This is the result"
  job_completed = true

  alert_attach_id = 1
  alert_gid = 1
  alert_sid = 1
  alert_rev = 1
  alert_msg = "this is an alert"

  pcaps={}
  pcaps[:attachment_id] = alert_attach_id
  pcaps[:gid] = alert_gid
  pcaps[:sid] = alert_sid
  pcaps[:rev] = alert_rev
  pcaps[:msg] = alert_msg

  pcap_test_alerts = [pcaps]

  job_pcap_tests = [pcap_test_alerts]

  # Release the message early
  client.ack(message.headers['message-id'])
  sleep(2)
  puts "back to you."

  job_pcap_tests.each do |pt_alerts|
    pt_alerts.each do |alert|
      puts ({ :id => alert[:attachment_id], :gid => alert[:gid], :sid => alert[:sid], :rev => alert[:rev], :message => alert[:msg] }).inspect
      client.publish "/queue/RulesUI.Snort.Run.Local.Test.Result",
                     {
                         :id => pcaps[:attachment_id],
                         :gid => alert[:gid],
                         :sid => alert[:sid],
                         :rev => alert[:rev],
                         :message => alert[:msg]
                     }.to_json
    end
  end
  # And notify the front end that the job is complete
  client.publish "/queue/RulesUI.Snort.Run.Local.Test.Result",
                 {
                     :job_id =>    request['job_id'],
                     :completed => job_completed,
                     :result =>    job_information,
                     :failed =>    job_failed,
                 }.to_json

end







