#!/usr/bin/env ruby

require 'open3'
require 'stomp'
require 'sfbugzilla'
require 'json'
require 'tmpdir'
require 'tempfile'
require 'vrt/rule_test_api'
require 'base64'

# Make sure we run from the application root
Dir.chdir ENV['APP_ROOT']

# General options
local_cache_path = File.expand_path('tmp/pcaps')

# Make sure our pcaps cache exists
if not File.exists?(local_cache_path)
	Dir.mkdir(local_cache_path)
end

stomp_options = {
	:hosts => [{ :login => "guest", :passcode => "guest", :host => 'mq.vrt.sourcefire.com', :port => 61613, :ssl => false }],
	:reliable => true,
}

# Create the xmlrpc instance for updating later
xmlrpc = Bugzilla::XMLRPC.new('bugzilla.vrt.sourcefire.com')

# Create our stomp client
client = Stomp::Connection.new(stomp_options)

# This queue should only have work jobs for All rule runs
client.subscribe "/queue/RulesUI.Snort.Run.All.Work", { :ack => :client }

# Initialize the API
RuleTestAPI.init('http://stewie.vrt.sourcefire.com:3389')

# Find the engine we should be using for these rules
engine_type = EngineType.where(:name => 'Persistent').first
snort_configuration = SnortConfiguration.where(:name => 'Open Source').first
rule_configuration = RuleConfiguration.where(:name => 'All Rules').first

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
  alerts = Array.new
  errors = Array.new
  job_id = nil

	begin

		# Start by parsing the request
		request = JSON.parse(message.body)

		# Release the message early
		client.ack(message.headers['message-id'])

    # Use this for hashing the pcaps
    sha256 = Digest::SHA256.new

    # Store the pcaps for testing
    pcaps = Hash.new

    # Save the job_id
    job_id = request['job_id'] 

    # Fetch all of the needed pcaps into the cache directory
    request['attachments'].each do |attachment_id|
      pcap_path = "#{local_cache_path}/#{attachment_id}"
			
      # Updated files get new attachment ids so no need to test the actual data
      if not File.exists?(pcap_path)
        attempts = 0

        begin 
          xmlrpc.token = request['cookie']
          bug = Bugzilla::Bug.new(xmlrpc)
          res = bug.attachments(:attachment_ids => attachment_id, :include_fields => ['data'])
          raise Exception.new("Bugzilla was unable to find attachment #{attachment_id}") if res.nil? or res['attachments'].nil?

          # Try to fetch and write this pcap
          IO.binwrite(pcap_path, res['attachments'].first[1]['data'])

        rescue Exception => e
          # Try 5 times to let Bugzilla stop sucking before bailing
          if attempts < 20
            attempts += 1
            sleep 1
            retry
          else
            errors << "Unable to fetch attachment #{attachment_id} from Bugzilla: #{e.to_s}"
            next
          end
        end
      end

      # Read the file to send
      pcap_data = IO.binread(pcap_path)

      # Start by hashing the pcap data
      sha = Digest.hexencode(sha256.digest(pcap_data))

      # See if the PCAP exists on the server
      pcap = Pcap.where(:file_hash => sha).first

      # Should we upload the pcap
      if pcap.nil?
        pcap = Pcap.create(:pcap => Base64.encode64(pcap_data))
      end

      # Make sure that worked
      if pcap.error?
        errors << pcap.error
      else
        pcaps[sha] = { :pcap_id => pcap.id, :attachment_id => attachment_id }
      end
    end

    test_pcaps = pcaps.map {|k,v| v[:pcap_id]} 

    # The rest client will only send a single entry if there is only one in the array
    if test_pcaps.size == 1
      test_pcaps << nil
    end

	  # Create the new job
    job = Job.create(:engine_id => engine.id, :pcaps => test_pcaps, :completed => false)

    # Make sure the job was created
    raise Exception.new("Failed to create job: #{job.error}") if job.error?
		
    # Wait for the job to finish
    until(job.completed == "1")
      sleep 1
      job = Job.find(job.id)
    end

    # Send back alerts
    job.pcap_tests.each do |pt|
      pt.alerts.each do |alert|
        alerts << 
          { 
            :id => pcaps[pt.pcap.file_hash][:attachment_id], 
            :gid => alert.gid, 
            :sid => alert.sid, 
            :rev => alert.rev, 
            :message => alert.msg 
          }
      end
    end

	rescue JSON::ParserError => e
    print "Failed to parse json message:"
    puts e.to_s
    puts e.backtrace.join("\n\t")
	rescue EOFError => e
	  errors << "Bugzilla appears to be fucking off: #{$!}\n#{e.backtrace.join("\n\t")}"
  rescue Exception => e
		errors << "An unknown error occurred: #{$!}\n#{e.backtrace.join("\n\t")}"
	end
  
  # Finally, send the results back
  puts alerts.inspect
  puts errors.inspect
  puts job_id
  unless job_id.nil?
    client.publish "/queue/RulesUI.Snort.Run.All.Result",
			{ 
        :job_id => job_id,
        :alerts => alerts,
        :errors => errors,
			}.to_json
  end
end
