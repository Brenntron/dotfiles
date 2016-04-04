#!/usr/bin/env ruby

######################
#=============
#client_local
#=============
# This file processes each selected rule against the local copy of the snort rules
######################

require 'open3'
require 'stomp'
require 'sfbugzilla'
require 'json'
require 'tmpdir'
require 'tempfile'
require 'vrt/rule_test_api'
require 'base64'
require 'pry'

# General options
local_cache_path = File.expand_path('tmp/pcaps')

if Rails.env =="development"
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
end


# Make sure our pcaps cache exists
if not File.exists?(local_cache_path)
  Dir.mkdir(local_cache_path)
end

cert = OpenSSL::X509::Certificate.new()
ssl_options= {}
stomp_options = {}
cert = OpenSSL::X509::Certificate.new(File.read(Rails.configuration.cert_file))
ssl_options= {ca_file: Rails.configuration.cert_file, client_cert: cert}
stomp_options = {
    :hosts => [{:login => "guest", :passcode => "guest", :host => Rails.configuration.amq_host, :port => 61613, :ssl => false}],
    :reliable => true, :closed_check => false
}

puts "talk to bugzilla"
# Create the xmlrpc instance for updating later
xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)

puts "create stomp client"
# Create our stomp client
client = Stomp::Connection.new(stomp_options)
client.subscribe "/queue/RulesUI.Snort.Run.Local.Test.Work", {:ack => :client}


puts "init API"
# Initialize the API
tries ||= 3
begin
  RuleTestAPI.init(Rails.configuration.ruletest_server, ssl_options)
rescue Exception => e
  retry unless (tries -= 1).zero?
end

puts "finding engine..."
# Find the engine we should be using for these rules
engine_type = EngineType.where(:name => 'Single').first
snort_configuration = SnortConfiguration.where(:name => 'Open Source').first
rule_configuration = RuleConfiguration.where(:name => 'Local Rules Only').first

puts "confirming..."
# Make sure everything was found
raise Exception.new("Unable to find Single engine type") if engine_type.nil?
raise Exception.new("Unable to find Open Source snort configuration") if snort_configuration.nil?
raise Exception.new("Unable to find Local Rules Only configuration") if rule_configuration.nil?

puts "setting engine..."
engine = Engine.where(
    :engine_type_id => engine_type[:id],
    :snort_configuration_id => snort_configuration[:id],
    :rule_configuration_id => rule_configuration[:id]).first
raise Exception.new("Unable to find the single All Rules Open Source engine") if engine.nil?

puts "listening to queue"
while message = client.receive
  begin
    puts "starting local rule work"
    puts "++++++++++++++++++++++++"
    # Start by parsing the request
    request = JSON.parse(message.body)

    puts request

    # Release the message early
    client.ack(message.headers['message-id'])

    # Use this for hashing the pcaps
    sha256 = Digest::SHA256.new

    # Store the pcaps for testing
    pcaps = Hash.new

    # Fetch all of the needed pcaps into the cache directory
    request['attachments'].each do |attachment_id|
      pcap_path = "#{local_cache_path}/#{attachment_id}"

      # Updated files get new attachment ids so no need to test the actual data
      if not File.exists?(pcap_path)
        attempts = 0

        # Retry if we get a bugzilla EOF error
        begin
          xmlrpc.token = request['cookie']
          bug = Bugzilla::Bug.new(xmlrpc)
          res = bug.attachments(:attachment_ids => attachment_id, :include_fields => ['data'])
          raise Exception.new("Bugzilla was unable to find attachment #{attachment_id}") if res.nil? or res['attachments'].nil?

          # Finally, we should actually have data
          IO.binwrite(pcap_path, res['attachments'].first[1]['data'])

        rescue Exception => e

          # Try 5 times to let Bugzilla stop sucking before bailing
          if attempts < 20
            attempts += 1
            sleep 1
            retry
          else
            raise Exception.new("Failed to read pcap from Bugzilla after 5 attempts")
          end
        end
      end

      # Read the file to send
      pcap_data = IO.binread(pcap_path)

      # Start by hashing the pcap data
      sha = Digest.hexencode(sha256.digest(pcap_data))
binding.pry
      # See if the PCAP exists on the server
      pcap = Pcap.where(:file_hash => sha).first

      # Should we upload the pcap
      if pcap.nil?
        pcap = Pcap.create(:pcap => Base64.encode64(pcap_data))
      end

      # Make sure that worked
      if pcap.error?
        raise Exception.new(pcap.error)
      else
        pcaps[sha] = {:pcap_id => pcap.attributes[:id], :attachment_id => attachment_id}
      end
    end

    test_pcaps = pcaps.map { |k, v| v[:pcap_id] }

    # The rest client will only send a single entry if there is only one in the array
    if test_pcaps.size == 1
      test_pcaps << ""
    end
binding.pry
    # Create the new job
    job = Job.create(:engine_id => engine.attributes[:id], :pcaps => test_pcaps, :completed => false, :local_rules => request['rules'].join("\n"))

    # Make sure the job was created
    raise Exception.new("Failed to create job: #{job.error}") if job.error?

    unless Rails.env == "development"
      # Wait for the job to finish
      until (job.completed == "1")
        sleep 1
        job = Job.find(job.attributes[:id])
      end
    end

    # Send back alerts
    job.pcap_tests.each do |pt|
      pt.alerts.each do |alert|
        puts ({:id => pcaps[pt.pcap.file_hash][:attachment_id], :gid => alert.gid, :sid => alert.sid, :rev => alert.rev, :message => alert.msg}).inspect

        client.publish "/queue/RulesUI.Snort.Run.Local.Test.Result",
                       {
                           :id => pcaps[pt.pcap.file_hash][:attachment_id],
                           :gid => alert.gid,
                           :sid => alert.sid,
                           :rev => alert.rev,
                           :message => alert.msg
                       }.to_json
      end
    end

    # And notify the front end that the job is complete
    client.publish "/queue/RulesUI.Snort.Run.Local.Test.Result",
                   {
                       :task_id => request['task_id'],
                       :completed => job.completed,
                       :result => job.information,
                       :failed => job.failed,
                   }.to_json

  rescue JSON::ParserError => e
    puts e.inspect
  rescue EOFError => e
    client.publish "/queue/RulesUI.Snort.Run.Local.Test.Result",
                   {
                       :task_id => request['task_id'],
                       :failed => true,
                       :completed => true,
                       :result => "Bugzilla appears to be fucking off: #{e.to_s}"
                   }.to_json
  rescue Exception => e
    client.publish "/queue/RulesUI.Snort.Run.Local.Test.Result",
                   {
                       :task_id => request['task_id'],
                       :failed => true,
                       :completed => true,
                       :result => "#{$!}\n#{e.backtrace.join("\n\t")}",
                   }.to_json

  end
end







