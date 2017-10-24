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
class SnortAllRulesResultProcessor < ApplicationProcessor


  subscribes_to Rails.configuration.amq_snort_all_result


  def on_message(message)
    Rails.logger.info( "============================")
    Rails.logger.info ("Configuring all rule results")
    result = JSON.parse(message)
    Rails.logger.info (result)

    if result['task_id'].present?

      begin
        # Make sure to close the job
        job = Task.find(result['task_id'])
        job.result ||= ""

        return if job.nil?

        attachments = Hash.new
        result['alerts'].each do |alert|
          attachments[alert['id']] ||= Array.new
          attachments[alert['id']] << alert
        end

        if result['errors'].size > 0
          job.failed = true

          result['errors'].each do |err|
            job.result << "#{err}\n"
          end
        end
        if attachments.any?
          Rails.logger.info ("Has alerts on attachments")
          attachments.each do |attachment_id, alerts|
            attachment = Attachment.find_by_bugzilla_attachment_id(attachment_id)
            bug = Bug.where(:id => attachment.bug_id).first
            rules_in_test = []
            # give some kind of feedback about the alerts on the pcap test
            job.result << "Alerts on pcap: #{attachment.file_name}\n" if attachment.present?
            job.result << "===============================================\n"
            job.result << "NONE" if alerts.count == 0

            alerts.each do |alert|
              begin
                rule = Rule.find_or_load(alert['sid'].to_i)

                if rule
                  Rails.logger.info( "Rule #{alert['gid']}:#{alert['sid']}:#{alert['rev']} was found")
                  job.result << "#{alert['gid']}:#{alert['sid']}:#{alert['rev']} #{alert['message']}\n"
                  unless attachment.nil? || attachment.pcap_alerts.map {|p| p.rule}.include?(rule)
                    attachment.pcap_alerts.create(rule: rule)
                  end
                else
                  job.failed = true
                  job.result << "#{alert['gid']}:#{alert['sid']}:#{alert['rev']} not found\n"
                end

              rescue Exception => e
                Rails.logger.info( "Rule failed #{e.message}")
                job.result << "#{e.to_s} -> #{e.message} : for #{alert['gid']}:#{alert['sid']}:#{alert['rev']}\n"
              rescue ActiveRecord::RecordNotUnique => e
                # Ignore these
              end
            end

            if bug.present?
              rules_in_test.each do |test_rule|
                Bug.link_action(bug.id, test_rule.sid, test_rule.gid)
              end
            end

            job.result << "\n"
          end

        else
          Rails.logger.info " NO alerts"
          job.result << "No alerts on any pcaps"
          job.result << "======================\n"
        end

        job.completed = true
        job.save
        Rails.logger.info "Job was saved."
      rescue Exception => e
        Rails.logger.info "there was an exception #{e.message}"
        puts e.to_s
        puts e.backtrace.join("\n")
      end
    else
      Rails.logger.info "NO TASK!"
    end
    Rails.logger.info( "Finished processing message")
  end
end
