require 'activemessaging/processor'
include ActiveMessaging::MessageSender
class TestRule
  publishes_to :snort_local_rules_test_work


  def self.send_work_msg(content, xmlrpc_token, bug)
    # be sure to collect all the attachments too but only the ones that are pcaps
    all_attachments = bug.attachments.inject([]) do | memo, attachment |
      memo << attachment.id if /^[-\w]+.pcap$/.match(attachment.file_name)
      memo
    end

    # TODO: collect rule content to insert in the local_rules. Dont use numbers.
    rules_content = []
    content.rules.each do |rule|
      rules_content << rule.on_rule_content
    end
    publish :snort_local_rules_test_work,
            {
              task_id: content.id,
              cookie: xmlrpc_token,
              pcaps: all_attachments,
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
    Alert.reset_local(@bug)
    @rules.each do |rule_id|
      @new_task.rules << Rule.where(id: rule_id).first unless nil
    end
    TestRule.send_work_msg(@new_task, @xmlrpc_token, @bug)
  end
end

