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
    puts "============================"
    puts "Configuring all rule results"
    result = JSON.parse(message)
    puts result
    
    unless result['task_id'].nil?

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
        if attachments.empty?
          attachments.each do |attachment_id, alerts|

            attachment = Attachment.find_by_bugzilla_attachment_id(attachment_id)
            # give some kind of feedback about the alerts on the pcap test
            job.result << "Alerts on pcap: #{attachment.file_name}\n"
            job.result << "===============================================\n"
            job.result << "NONE" if alerts.count == 0

            alerts.each do |alert|
              begin
                rule = Rule.by_sid(alert['sid'].to_i, alert['gid'].to_i).first

                if rule.nil?
                  if alert['gid'].to_i == 1
                    rule = Rule.new(:rule_content => Rule.find_current_rule(alert['sid'].to_i))
                  else
                    rule = Rule.new(:gid => alert['gid'].to_i, :sid => alert['sid'].to_i, :rev => alert['rev'].to_i, :message => alert['message'])
                  end

                  rule.state = Rule::UNCHANGED_STATE
                  rule.edit_status = Rule::EDIT_STATUS_NEW
                  rule.publish_status = Rule::PUBLISH_STATUS_SYNCHED
                end

                # The rule should have extracted if it was valid
                if rule.valid?
                  job.result << "#{alert['gid']}:#{alert['sid']}:#{alert['rev']} #{alert['message']}\n"
                  rule.save(:validate => false)
                  attachment.pcap_alerts.create(rule: rule)
                else
                  if rule.message.nil?
                    job.failed = true
                    rule.errors.each do |k, v|
                      job.result << "#{rule.version} #{v}\n"
                    end
                  else
                    job.result << "#{alert['gid']}:#{alert['sid']}:#{alert['rev']} #{alert['message']}\n"
                    rule.save(:validate => false)
                    attachment.pcap_alerts.create(rule: rule)
                  end
                end

              rescue RuleError => e
                job.failed = true
                job.result << "#{e.to_s} for sid #{alert['sid']}\n"
              rescue ActiveRecord::RecordNotUnique => e
                # Ignore these
              end
            end
            job.result << "\n"
          end

        else
          job.result << "No alerts on any pcaps"
          job.result << "======================\n"
        end

        job.completed = true
        job.save
      rescue Exception => e
        puts e.to_s
        puts e.backtrace.join("\n")
      end
    end
  end
end
