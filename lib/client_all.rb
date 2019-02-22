#!/usr/bin/env rails runner

######################
#=============
#client_all
#=============
# This file tests each attachment(a pcap) against all the snort rules. It returns a number of alerts for each rule it has a problem with.
# this is an example of the result:
# ==========================================================
#
# Job Information:
#
# ==========================================================
#
# Submitted at: 2017-03-09 16:52:02
#
# Completed at: 2017-03-09 16:52:13
#
# Failed: 0
#
# ==========================================================
#
#
# ==========================================================
#
# Alerts:
#
# ==========================================================
# 2015-0329-72514-apsb-144878-1.pcap
#     1:33469:1 FILE-FLASH Adobe Flash Player arbitrary code execution attempt
#     1:38027:2 POLICY-OTHER Adobe Flash file containing ExternalInterface function download detected
#     1:33471:2 FILE-FLASH Adobe Flash Player arbitrary code execution attempt
# 2015-0329-72514-apsb-144878-2.pcap
#     1:38027:2 POLICY-OTHER Adobe Flash file containing ExternalInterface function download detected
#     1:33471:2 FILE-FLASH Adobe Flash Player arbitrary code execution attempt
# FP-2015-0339-73088-apsb-145641-3.pcap
#     No alerts.
# cve_2015_0329_adobe_flash_pcre_regex_compilation_extended_unicode_comment_code_execution.pcap
#     No alerts.
# decompressed-bp.swf-smtp.pcap
#     No alerts.
# 2015-0329.swf-http.pcap
#     1:38027:2 POLICY-OTHER Adobe Flash file containing ExternalInterface function download detected
# ==========================================================
######################

require 'httpi'
require 'curl'
require 'open3'
require 'stomp'
require 'json'
require 'tmpdir'
require 'tempfile'
require 'base64'
require 'pry'

# Make sure we run from the application root
Dir.chdir Rails.root


HTTPI.log = false

req = HTTPI::Request.new
req.auth.gssnegotiate

req.auth.ssl.ca_cert_file = Rails.configuration.cert_file


# General options
local_cache_path = File.expand_path("#{Rails.root}/tmp/pcaps")

if Rails.env =="development"
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
end

# Make sure our pcaps cache exists
unless File.exists?(local_cache_path)
  Dir.mkdir(local_cache_path)
end

max_wait_for_job = 120 #seconds

stomp_options = {}
stomp_options = {
    :hosts => [{:login => "guest", :passcode => "guest", :host => Rails.configuration.amq_host, :port => 61613, :ssl => false}],
    :reliable => true, :closed_check => false
}
Rails.logger.info("#{Time.now} -> xmlrpc to bugzilla")
# Create the xmlrpc instance for updating later
xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)

Rails.logger.info("#{Time.now} -> create stomp client and subscribe to amq")
# Create our stomp client
client = Stomp::Connection.new(stomp_options)
# This queue should only have work jobs for All rule runs
client.subscribe Rails.configuration.subscribe_all_work, {:ack => :client}

Rails.logger.info("#{Time.now} -> listening to ALL queue")
while message = client.receive
  Rails.logger.info( "#{Time.now} -> starting all rule work")
  pcap_alerts = Array.new
  errors = Array.new
  task_id = nil

  begin
    # Start by parsing the request
    request = JSON.parse(message.body)
    Rails.logger.info("#{Time.now} -> received request")
    Rails.logger.debug(request)

    # Release the message early
    client.ack(message.headers['message-id'])

    # Store the pcaps for testing
    pcaps = Hash.new
    pcaps[""] = 0 #rulesAPI doesnt like single pcaps it wants at least 2 adding a blank entry causes it to not fail

    # Save the task_id
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

          if res['attachments'].first[1]['data'].size < 500
            Rails.logger.debug("Resource data is not found. Here is what the variable contains: #{res}" )
          else
            Rails.logger.debug("Resource data is found. This is the size from bugzilla: #{res['attachments'].first[1]['data'].size}")
          end

          raise Exception.new("Bugzilla was unable to find attachment #{attachment_id}") if res.nil? or res['attachments'].nil?
          raise Exception.new("Bugzilla could not retrieve data for attachment #{attachment_id}") if res['attachments'].first[1]['data'].empty?
          Rails.logger.debug("#{Time.now} -> Found attachments in bugzilla")
          # Finally, we should actually have data
          bytes_written = IO.binwrite(pcap_path, res['attachments'].first[1]['data'])

          #file size check here
          Rails.logger.debug ("bytes_written: #{bytes_written}")
        rescue Exception => e
          if res['attachments'].first[1]['data'].empty?
            raise Exception.new(e.message)
          end
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

      #filesize check here
      Rails.logger.debug ("pcap_data: #{pcap_data.size}")

      req.url = "#{Rails.configuration.ruletest_server}/pcaps"

      # Should we upload the pcap
      req.body = Curl::PostField.file("pcap", pcap_path) #build the curl request
      #now we make the request as a post request
      Rails.logger.debug("#{Time.now} ->  Making pcap request to #{Rails.env} ruletest server")
      resp = HTTPI.post req do |http|
        http.multipart_form_post = true
      end

      # Make sure that worked
      if resp.code != 200 and resp.code != 201 #if it didnt work the say so
        raise Exception.new("Upload of #{attachment_id} failed: #{resp.code} - #{resp.body}")
      else
        pcaps[JSON.parse(resp.body)['id']] = attachment_id #now we compile a hash using ids as keys and the pcaps as values
      end
    end

    test_pcaps = pcaps.map { |k, v| k.to_i }

    # The rest client will only send a single entry if there is only one in the array
    if test_pcaps.size < 1
      raise Exception.new("No pcaps uploaded for testing")
    end

    req.url = "#{Rails.configuration.ruletest_server}/jobs"

    # Create the new job
    Rails.logger.info( "Creating persistent job")
    req.body = {
        :pcaps => test_pcaps,
        :engine_id => 1, #TODO: figure out what these ids mean and why we dont generate them based off of the snort and rule configurations
    }
    Rails.logger.debug("#{Time.now} ->  Making job request to #{Rails.env} ruletest server")
    resp = HTTPI.post(req) #make the request

    if resp.code != 200 and resp.code != 201
      raise Exception.new("Failed to create new job with pcaps (#{pcaps}): #{resp.code} - #{resp.body}")
    end

    # Make sure we have a job id
    job_id = JSON.parse(resp.body)['id']

    # Wait for the job to finish
    req.url = "#{Rails.configuration.ruletest_server}/jobs/#{job_id}"

    job = {}

    pcaps.except!("") #remove the blank key that we created for ruleAPI because we dont need it after the job is finished

    unless Rails.env == "development"
      # Wait for the job to finish
      begin
        Rails.logger.info("Waiting on job #{job_id} to complete: ")

        Timeout::timeout(max_wait_for_job) do
          while true
            resp = HTTPI.get(req)
            Rails.logger.info("Response was: #{resp.inspect}")

            if resp.code != 200
              raise Exception.new("Failed to fetch job status for #{job_id} #{resp.code}: #{resp.body}")
            else
              job = JSON.parse(resp.body)
              Rails.logger.info("Job is: #{job.inspect}")

              if job['completed'] == 1
                Rails.logger.info("Job Completed")
                if job['failed'] == 1
                  Rails.logger.info( "Job failed: #{job}")
                else
                  Rails.logger.info("Job Did Not Fail. getting pcaps...")
                  pcaps.each do |pcap_id, pcap_name|
                    Rails.logger.info( "pcap_id: #{pcap_id} --- pcap_name: #{pcap_name}")

                    # Fetch the associated pcap tests
                    req.url = "#{Rails.configuration.ruletest_server}/pcap_tests?job_id=#{job_id}&pcap_id=#{pcap_id}"
                    Rails.logger.info("fetching requests from: #{req.url.inspect}")
                    pcap_response_body = HTTPI.get(req).body
                    Rails.logger.info("response was: #{pcap_response_body.inspect}")
                    JSON.parse(pcap_response_body).each do |pt|
                      Rails.logger.info("request returned pt is: #{pt.inspect}")

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
                          Rails.logger.info( "\t#{alert['gid']}:#{alert['sid']}:#{alert['rev']} #{alert['msg']}")
                          pcap_alerts <<
                              {
                                  :id => pcap_name,
                                  :gid => alert['gid'],
                                  :sid => alert['sid'],
                                  :rev => alert['rev'],
                                  :message => alert['msg']
                              }
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
            Rails.logger.info(".")
            sleep 1
          end
        end

      rescue Exception => e
        Rails.logger.error("Not a time out error it was something else. #{e.message}")
        raise Exception.new(e.message)
      rescue Timeout::Error => e
        errors << "Timed out waiting for #{job_id} to finish. Either Rules API is really slow or the poller down again."
        Rails.logger.error( "Timed out waiting for #{job_id} to finish")
      end

    end


  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse json message:#{e.to_s}")
    Rails.logger.error( e.backtrace.join("\n\t"))
    errors << "Failed to parse json message:#{e.to_s}. #{e.backtrace.join("\n\t")}"
  rescue EOFError => e
    Rails.logger.error("Bugzilla appears to be fucking off: #{$!}\n#{e.backtrace.join("\n\t")}")
    errors << "Bugzilla appears to be fucking off: #{$!}\n#{e.backtrace.join("\n\t")}"
  rescue Exception => e
    Rails.logger.error("Rails encountered an error: #{e.message}")
    errors << e.message
  end

  # Finally, send the results back
  unless task_id.nil?
    Rails.logger.info( "#{Time.now} -> Publishing to AMQ")
    client.publish Rails.configuration.publish_all_result,
                   {
                       :task_id => task_id,
                       :alerts => pcap_alerts,
                       :errors => errors,
                   }.to_json
  end
end
