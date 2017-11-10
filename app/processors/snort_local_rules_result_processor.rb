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
#   Num  SID  GID Rev  Checks Matches  Alerts  Microsecs Avg/Check Avg/Match Avg/Nonmatch Disabled
#   ===  ===  === ===  ====== =======  ======  ========= ========= ========= ============ ========
#    1  23993  1   5     6       2       1        23        4.0       9.7        1.1         0
#
######################
class SnortLocalRulesResultProcessor < ApplicationProcessor

  NEW_RULE_ID_BIAS = 1_000_000 unless defined? NEW_RULE_ID_BIAS

  subscribes_to Rails.configuration.amq_snort_local_result


  def on_message(message)
    Rails.logger.info ("==============================")
    Rails.logger.info ("Configuring local rule results")
    # if you need a test message the following is a sample of what the rulesapi returns after a successful test.
    # message = '{"id":79922, "gid":1, "sid":26471, "rev":6, "message":"PROTOCOL-FTP VanDyke AbsoluteFTP LIST command stack buffer overflow attempt"}'
    result = JSON.parse(message)
    # result['failed']= false
    # result['result'] = "Reading network traffic from \"/tmp/a5bDQ8jSHL/02657a9ec8271e5aa0bfa33233cedc1ec69f1392b46dec5f05f1eb3d9d4e7490\" with snaplen = 1514\n01/01--3:-28:-16.743594  [**] [1:24866:2] SERVER-IIS Microsoft Windows IIS UNC mapped virtual host file source code access attempt [**] [Classification: Attempted Information Leak] [Priority: 2] {TCP} 1.1.181.139:51383 -> 1.2.187.55:80\nStream reassembled packet\n01/01--3:-28:-16.743594 02:1A:C5:01:00:00 -> 02:1A:C5:02:00:00 type:0x800 len:0x10A\n1.1.181.139:51383 -> 1.2.187.55:80 TCP TTL:255 TOS:0x0 ID:14730 IpLen:20 DgmLen:252\n***AP*** Seq: 0x827E76E4  Ack: 0x99B2FE3E  Win: 0x3FFF  TcpLen: 20\n47 45 54 20 2F 64 65 66 61 75 6C 74 2E 61 73 70  GET /default.asp\n25 35 63 20 48 54 54 50 2F 31 2E 31 0D 0A 48 6F  %5c HTTP/1.1..Ho\n73 74 3A 20 79 62 4D 76 4C 47 74 0D 0A 55 73 65  st: ybMvLGt..Use\n72 2D 41 67 65 6E 74 3A 20 4D 6F 7A 69 6C 6C 61  r-Agent: Mozilla\n2F 35 2E 30 20 28 57 69 6E 64 6F 77 73 3B 20 55  /5.0 (Windows; U\n3B 20 57 69 6E 64 6F 77 73 20 4E 54 20 35 2E 31  ; Windows NT 5.1\n3B 20 65 6E 2D 55 53 29 20 41 70 70 6C 65 57 65  ; en-US) AppleWe\n62 4B 69 74 2F 35 32 35 2E 31 39 20 28 4B 48 54  bKit/525.19 (KHT\n4D 4C 2C 20 6C 69 6B 65 20 47 65 63 6B 6F 29 20  ML, like Gecko) \n56 65 72 73 69 6F 6E 2F 33 2E 31 2E 32 20 53 61  Version/3.1.2 Sa\n66 61 72 69 2F 35 32 35 2E 32 31 0D 0A 41 63 63  fari/525.21..Acc\n65 70 74 3A 20 2A 2F 2A 0D 0A 43 6F 6E 6E 65 63  ept: */*..Connec\n74 69 6F 6E 3A 20 6B 65 65 70 2D 61 6C 69 76 65  tion: keep-alive\n0D 0A 0D 0A                                      ....\n\n=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+\n\n\nRule Profile Statistics (worst 10 rules)\n==========================================================\n   Num      SID GID Rev     Checks   Matches    Alerts           Microsecs  Avg/Check  Avg/Match Avg/Nonmatch   Disabled\n   ===      === === ===     ======   =======    ======           =========  =========  ========= ============   ========\n     1    15468   1  15          1         0         0                   1        2.0        0.0          2.0          0\n     2    24866   1   2         14         1         1                  14        1.0        9.3          0.4          0\n     3     7751   1   4          4         0         0                   2        0.7        0.0          0.7          0\n     4    31332   1   7          2         0         0                   1        0.5        0.0          0.5          0\n     5     5813   1   4          5         0         0                   2        0.5        0.0          0.5          0\n     6    19326   1   9          3         0         0                   1        0.5        0.0          0.5          0\n     7    17447   1   5          7         0         0                   1        0.3        0.0          0.3          0\n     8    20665   1   7         14         0         0                   3        0.2        0.0          0.2          0\n     9    20664   1   7         14         0         0                   2        0.2        0.0          0.2          0\n    10    24867   1   2         14         0         0                   2        0.2        0.0          0.2          0\n"
    Rails.logger.info( result)
    attachment = Attachment.find_by_bugzilla_attachment_id(result['id'])

    # Is this an alert message or a job completion message?
    if result['completed'] and result['task_id']
      Rails.logger.info( "processing Task : #{result['task_id']}")
          # this code is for a job completed message
      job = Task.find(result['task_id'])
      job.result = result['result']
      job.completed = true
      job.failed = result['failed']
      job.save

      job.set_rule_tested unless job.failed

      # Nothing to do on a failed job
      if job.failed
        Rails.logger.info( "Job Failed. Returning from processing")
        return
      end

      # Parse performance results (as Donald Knuth would approve)
      job.update_rule_stats
    else
      Rails.logger.info( "processing local Alert : #{result['sid']}")
      # This code is for an alert message from the queue
      # Note: for a new rule, a temporary sid is used as a million plus the rule id.
      if result['sid'].to_i > 1000000
        rule = Rule.where(id: (result['sid'].to_i - 1000000)).first
      else
        rule = Rule.by_sid(result['sid'], result['gid']).first
      end

      # what this code is doing is attaching an attachment to a rule to indicate that it alerted on the rule.
      # we then read the list of attachments on the rule to determine which ones alerted. basically all attachments
      # on a rule are alerts
      # Watch out for preproc and file-identify rules in alerts
      unless rule.nil?
        Rails.logger.info( "Rule wasnt nill")
        begin
          attachment.local_alerts.create(rule: rule) unless attachment.local_alerts.map{|p| p.rule}.include?(rule)
        rescue ActiveRecord::RecordNotUnique => e
          # Ignore
        end

        Rails.logger.info( "saving rule")
        rule.save
      end
    end
    Rails.logger.info( "Finished processing parsed message")
  end
end
