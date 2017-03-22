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
class SnortLocalRulesResultProcessor < ApplicationProcessor

  subscribes_to :snort_local_rules_test_result

  def on_message(message)
    puts "=============================="
    puts "Configuring local rule results"
    result = JSON.parse(message)

    attachment = Attachment.find_by_bugzilla_attachment_id(result['id'])

    # Is this an alert message or a job completion message?
    if result['completed'] and result['task_id']
      # this code is for a job completed message
      job = Task.find(result['task_id'])
      job.result = result['result']
      job.completed = true
      job.failed = result['failed']
      job.save

      # Nothing to do on a failed job
      return if job.failed

      # Parse performance results (as Donald Knuth would approve)
      job.update_rule_stats

    else
      # This code is for an alert message from the queue
      if result['sid'].to_i > 1000000
        rule = Rule.find_by_id(result['sid'].to_i - 1000000)
      else
        rule = Rule.find_by_sid(result['sid'])
      end

      # what this code is doing is attaching an attachment to a rule to indicate that it alerted on the rule.
      # we then read the list of attachments on the rule to determine which ones alerted. basically all attachments
      # on a rule are alerts
      # Watch out for preproc and file-identify rules in alerts
      unless rule.nil?
        begin
          rule.attachments << attachment
          attachment.local_alerts.create(rule: rule)
        rescue ActiveRecord::RecordNotUnique => e
          # Ignore
        end

        rule.save
      end
    end
  end
end
