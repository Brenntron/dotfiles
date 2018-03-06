require 'httpi'
require 'curl'
require 'json'
require 'timeout'

HTTPI.log = false

req = HTTPI::Request.new
req.auth.gssnegotiate

local_rules = nil

if ARGV.size < 2
  puts "Usage: ruby rule_test.rb [*.rules] <pcap> <pcap> <pcap> ..."
  exit(0)
end


if ARGV[0] =~ /\.rules$/
  File.open(ARGV[0], 'r') do |f|
    local_rules = f.read()        #get some rules: this is a local rule test
  end
  pcap_files = ARGV[1..-1]        #this should be all the pcaps that are associated with the bug

else
  #this is where we woudl do all rules because none were passed in
  pcap_files = ARGV
end

# The client has to keep track of ids to filenames
pcaps = Hash.new

# First, upload all pcaps
req.url = 'https://ruleapitest.vrt.sourcefire.com/pcaps'

pcap_files.each do |pcap_file|
  if not File.file?(pcap_file)     #check to see if the files were downloaded properly
    puts "#{pcap_file} doesn't exist"
    exit(0)
  else
    req.body = Curl::PostField.file("pcap", pcap_file) #build the curl request

    resp = HTTPI.post req do |http|           #now we make the request as a post request
      http.multipart_form_post = true
    end

    if resp.code != 200 and resp.code != 201         #if it didnt work the say so
      puts "Upload of #{pcap_file} failed: #{resp.code} - #{resp.body}"
      exit(0)
    else
      pcaps[JSON.parse(resp.body)['id']] = pcap_file   #now we compile a hash using ids as keys and the pcaps as values
    end
  end
end

# Make sure there were acutally pcaps to send
if pcaps.size < 1
  puts "No pcaps uploaded for testing"
  exit(0)
end

# Now create our job
req.url = 'https://ruleapitest.vrt.sourcefire.com/jobs'

if local_rules        #if rules exist meaning they were passed in for a local test then do stuff
  puts "Creating local job"
  req.body = {
      :pcaps => pcaps.keys,
      :engine_id => 2,    #TODO: figure out what these ids mean and why we dont generate them based off of the snort and rule configurations
      :local_rules => local_rules
  }
end

#it would seem to me that the engine id is based off of what type of test you want to run.

resp = HTTPI.post(req)  #make the request

if resp.code != 200 and resp.code != 201
  puts "Failed to create new job with pcaps (#{pcaps}): #{resp.code} - #{resp.body}"
  exit(0)
end

# Make sure we have a job id
job_id = JSON.parse(resp.body)['id']

# Wait for the job to finish
req.url = "https://ruleapitest.vrt.sourcefire.com/jobs/#{job_id}"

begin
  print "Waiting on job #{job_id} to complete: "

  Timeout::timeout(30) do
    while true
      resp = HTTPI.get(req)

      if resp.code != 200
        puts "Failed to fetch job status for #{job_id} #{resp.code}: #{resp.body}"
        exit(0)
      else
        job = JSON.parse(resp.body)

        if job['completed'] == 1
          puts
          if job['failed'] == 1
            puts "Job failed: #{job}"
          else
            pcaps.each do |pcap_id, pcap_name|
              puts "#{pcap_name}:"

              # Fetch the associated pcap tests
              req.url = "https://ruleapitest.vrt.sourcefire.com/pcap_tests?job_id=#{job_id}&pcap_id=#{pcap_id}"
              JSON.parse(HTTPI.get(req).body).each do |pt|

                # Now fetch the alerts
                req.url = "https://ruleapitest.vrt.sourcefire.com/alerts?pcap_test_id=#{pt['id']}"
                alerts = JSON.parse(HTTPI.get(req).body)

                if alerts.size == 0
                  puts "\tNO ALERTS"
                else
                  alerts.each do |alert|
                    puts "\t#{alert['gid']}:#{alert['sid']}:#{alert['rev']} #{alert['msg']}"
                  end
                end
              end
            end
          end

          # We are done either way
          break
        end
      end

      # Wait before trying again
      print "."
      sleep 1
    end
  end

rescue Timeout::Error => e
  puts "Timed out waiting for #{job_id} to finish"
end
