require 'activemessaging/processor'
include ActiveMessaging::MessageSender
class TestRule

  publishes_to Rails.configuration.amq_snort_local


  def self.send_work_msg(task, xmlrpc_token, bug)
    # be sure to collect all the attachments too but only the ones that are pcaps
    all_attachments = bug.attachments.inject([]) do |memo, attachment|
      memo << attachment if File.extname(attachment.file_name.downcase) == ".pcap" && attachment.is_obsolete == false
      memo
    end
    Rails.logger.info("rule testing: Testing attachments #{all_attachments.pluck(:file_name).join(", ")}")

    rules_content = []
    task.rules.each do |rule|
      rules_content << rule.test_rule_content
    end

    publish Rails.configuration.amq_snort_local,
            {
              task_id: task.id,
              cookie: xmlrpc_token,
              pcaps: all_attachments.pluck(:id),
              rules: rules_content
            }.to_json
  end

  def initialize(new_task, xmlrpc_token, bug, rules)
    @xmlrpc_token = xmlrpc_token
    @new_task = new_task
    @bug = bug
    @rules = rules
  end

  def send_work_msg
    Alert.reset_local(@bug, @rules)
    @rules.each do |rule_id|
      @new_task.rules << Rule.where(id: rule_id).first unless nil
    end
    TestRule.send_work_msg(@new_task, @xmlrpc_token, @bug)
  end
end

