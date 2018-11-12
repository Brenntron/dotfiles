#!/usr/bin/env rails runner

######################
#=============
#client_local
#=============
# This file processes each selected rule against each attachment in the bug
# output should look like this:
#
#
# Reading network traffic from "/tmp/t7nB8WvvhV/2c9b25483e99099e9585096dde1373a1e186a5549f5d93ef606ca5d4a9f541e3" with snaplen = 1514
# Reading network traffic from "/tmp/t7nB8WvvhV/319df6e776de5cdfb18ef48f6b51eec379739b02101ab5eccb18cabd48aca358" with snaplen = 1514
# Reading network traffic from "/tmp/t7nB8WvvhV/5328cea7c0214754a1f95f42768341fb0c69f96298e9b5150bbc517a3762e4b1" with snaplen = 1514
# 06/18-17:21:12.629509  [**] [1:23993:5] SERVER-OTHER Dhcpcd packet size buffer overflow attempt [**] [Classification: Attempted Administrator Privilege Gain] [Priority: 1] {UDP} 10.1.12.51 -> 10.3.12.52
#
# some hex here
#
#     =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
#
#
# Reading network traffic from "/tmp/t7nB8WvvhV/a194548bcb936b066074d72ae927d3540438d03cd18c062922ac8e738c79e4b0" with snaplen = 1514
# 06/28-09:22:34.693357  [**] [1:23993:5] SERVER-OTHER Dhcpcd packet size buffer overflow attempt [**] [Classification: Attempted Administrator Privilege Gain] [Priority: 1] {UDP} 192.168.5.1 -> 192.168.5.200
#
# some hex here
#
#     =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
#
#
# Rule Profile Statistics (worst 10 rules)
# ==========================================================
#     Num      SID GID Rev     Checks   Matches    Alerts           Microsecs  Avg/Check  Avg/Match Avg/Nonmatch   Disabled
#     ===      === === ===     ======   =======    ======           =========  =========  ========= ============   ========
#     1    23993   1   5          6         2         1                  23        4.0        9.7          1.1          0
#
######################

require 'httpi'
require 'curl'
require 'open3'
require 'stomp'
# require 'sfbugzilla'
require 'json'
require 'tmpdir'
require 'tempfile'
require 'base64'
require 'pry'

HTTPI.log = false

req = HTTPI::Request.new
req.auth.gssnegotiate

req.auth.ssl.ca_cert_file = Rails.configuration.cert_file

# General options
local_cache_path = File.expand_path("#{Rails.root}/tmp/pcaps")

if Rails.env == "development"
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
end


# Make sure our pcaps cache exists
unless File.exists?(local_cache_path)
  Dir.mkdir(local_cache_path)
end
stomp_options = {}
stomp_options = {
    :hosts => [{:login => "guest", :passcode => "guest", :host => Rails.configuration.amq_host, :port => 61613, :ssl => false}],
    :reliable => true, :closed_check => false
}
Rails.logger.info("#{Time.now} -> talk to bugzilla")
# Create the xmlrpc instance for updating later
xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)

Rails.logger.info( "#{Time.now} -> create stomp client")
# Create our stomp client
client = Stomp::Connection.new(stomp_options)
client.subscribe Rails.configuration.subscribe_local_work, {:ack => :client}

Rails.logger.info( "#{Time.now} -> listening to LOCAL queue")
while message = client.receive
  task_id = nil
  begin
    Rails.logger.info( "#{Time.now} -> starting local rule work")
    # Start by parsing the request
    request = JSON.parse(message.body)

    Rails.logger.debug("#{Time.now} -> #{request}")

    # Release the message early
    client.ack(message.headers['message-id'])

    # Store the pcaps for testing
    pcaps = Hash.new
    pcaps[""] = 0 #rulesAPI doesnt like single pcaps it wants at least 2 adding a blank entry causes it to not fail

    task_id = request['task_id']
    # Fetch all of the needed pcaps into the cache directory
    request['pcaps'].each do |attachment_id|
      pcap_path = "#{local_cache_path}/#{attachment_id}"

      # Updated files get new attachment ids so no need to test the actual data
      unless File.exists?(pcap_path)
        attempts = 0

        # Retry if we get a bugzilla EOF error
        begin
          xmlrpc.token = request['cookie']

          bug = Bugzilla::Bug.new(xmlrpc)
          res = bug.attachments(:attachment_ids => attachment_id, :include_fields => ['data'])

          raise Exception.new("Bugzilla was unable to find attachment #{attachment_id}") if res.nil? or res['attachments'].nil?
          Rails.logger.debug("#{Time.now} -> Found attachments in bugzilla")
          # Finally, we should actually have data
          bytes_written = IO.binwrite(pcap_path, res['attachments'].first[1]['data'])

        rescue Exception => e

          # Try 5 times to let Bugzilla stop sucking before bailing
          if attempts < 5
            attempts += 1
            sleep 1
            retry
          else
            raise Exception.new("Failed to read pcap from Bugzilla after 5 attempts. Exception was: #{e.to_s}, bytes written: #{bytes_written}")
          end
        end
      end

      # Read the file to send
      pcap_data = IO.binread(pcap_path)

      req.url = "#{Rails.configuration.ruletest_server}/pcaps"

      # Should we upload the pcap
      req.body = Curl::PostField.file("pcap", pcap_path) #build the curl request
      #now we make the request as a post request
      Rails.logger.debug("#{Time.now} ->  Making pcap request to #{Rails.env} ruletest server")
      resp = HTTPI.post req do |http|
        http.multipart_form_post = true
      end


      # Make sure that worked
      if resp.code != 200 and resp.code != 201         #if it didnt work the say so
        raise Exception.new("Upload of #{attachment_id} failed:\n #{resp.code} - #{resp.body}")
      else
        pcaps[JSON.parse(resp.body)['id']] = attachment_id   #now we compile a hash using ids as keys and the pcaps as values
      end
    end

    test_pcaps = pcaps.map {|k,v| k.to_i}

    # The rest client will only send a single entry if there is only one in the array
    if test_pcaps.size < 1
      raise Exception.new("No pcaps uploaded for testing")
    end

    req.url = "#{Rails.configuration.ruletest_server}/jobs"

    # Create the new job
    req.body = {
        :pcaps => pcaps.keys,
        :engine_id => 2,    #TODO: figure out what these ids mean and why we dont generate them based off of the snort and rule configurations
        :local_rules => request['rules'].join("\n")
    }
    Rails.logger.debug("#{Time.now} ->  Making job request to #{Rails.env} ruletest server")
    resp = HTTPI.post(req)  #make the request

    # Make sure the job was created
    if resp.code != 200 and resp.code != 201
      raise Exception.new("Failed to create new job with pcaps (#{pcaps}): #{resp.code} - #{resp.body}")
    end

    job_id = JSON.parse(resp.body)['id']

    # Wait for the job to finish
    req.url = "#{Rails.configuration.ruletest_server}/jobs/#{job_id}"
    job={}
    pcaps.except!("") #remove the blank key that we created for ruleAPI because we dont need it after the job is finished

    unless Rails.env == "development"
      # Wait for the job to finish
      begin
        Rails.logger.info("Waiting on job #{job_id} to complete: ")

        Timeout::timeout(120) do
          while true
            resp = HTTPI.get(req)
            Rails.logger.info("Response was: #{resp.inspect}")

            if resp.code != 200
              raise Exception.new( "Failed to fetch job status for #{job_id} #{resp.code}: #{resp.body}")
            else
              job = JSON.parse(resp.body)

              if job['completed'] == 1
                Rails.logger.info("job completed")
                if job['failed'] == 1
                  Rails.logger.info("Job failed: #{job}")
                else
                  pcaps.each do |pcap_id, pcap_name|
                    Rails.logger.info("#{pcap_name}:")

                    # Fetch the associated pcap tests
                    req.url = "#{Rails.configuration.ruletest_server}/pcap_tests?job_id=#{job_id}&pcap_id=#{pcap_id}"
                    Rails.logger.info("fetching requests from: #{req.url.inspect}")
                    pcap_response_body = HTTPI.get(req).body
                    Rails.logger.info("response was: #{pcap_response_body.inspect}")
                    JSON.parse(pcap_response_body).each do |pt|

                      # Now fetch the alerts
                      req.url = "#{Rails.configuration.ruletest_server}/alerts?pcap_test_id=#{pt['id']}"
                      Rails.logger.info("fetching requests from: #{req.url.inspect}")
                      alert_response_body = HTTPI.get(req).body
                      Rails.logger.info("response was: #{alert_response_body.inspect}")
                      alerts = JSON.parse(alert_response_body)

                      if alerts.size == 0
                        Rails.logger.info( "\tNO ALERTS")
                      else
                        alerts.each do |alert|
                          Rails.logger.info( "#{Time.now} -> Publishing RESULTS:")
                          Rails.logger.info( "\t#{alert['gid']}:#{alert['sid']}:#{alert['rev']} #{alert['msg']}")
                          client.publish Rails.configuration.publish_local_result,
                                         {
                                             :id => pcap_name,
                                             :gid => alert['gid'],
                                             :sid => alert['sid'],
                                             :rev => alert['rev'],
                                             :message => alert['msg']
                                         }.to_json
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
            sleep 1
          end
        end

      rescue Exception => e
        raise Exception.new( e.message )
      rescue Timeout::Error => e
        Rails.logger.error("Timed out waiting for #{job_id} to finish")
        client.publish Rails.configuration.publish_local_result,
                       {
                           :task_id => task_id,
                           :failed => true,
                           :completed => true,
                           :result => "Timed out waiting for #{job_id} to finish. Either Rules API is really slow or the poller down again."
                       }.to_json
      end

    end
    Rails.logger.info("Publishing back to MQ for job #{job_id}")
    # And notify the front end that the job is complete
    client.publish Rails.configuration.publish_local_result,
                   {
                       :task_id => task_id,
                       :completed => job['completed'],
                       :result => job['information'],
                       :failed => job['failed'],
                   }.to_json

  rescue JSON::ParserError => e
    Rails.logger.error(e.inspect)
  rescue EOFError => e
    Rails.logger.error("error Publishing eof error: #{e.message} back to MQ for job #{job_id}")
    client.publish Rails.configuration.publish_local_result,
                   {
                       :task_id => task_id,
                       :failed => true,
                       :completed => true,
                       :result => "Bugzilla appears to be fucking off: #{e.to_s}"
                   }.to_json
  rescue Exception => e
    Rails.logger.error("Error Publishing exception: #{e.message}, back to MQ for job #{job_id}")
    client.publish Rails.configuration.publish_local_result,
                   {
                       :task_id => task_id,
                       :failed => true,
                       :completed => true,
                       :result => "#{$!}\n#{e.backtrace.join("\n\t")}",
                   }.to_json

  end
end







