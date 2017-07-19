require 'activemessaging/processor'
include ActiveMessaging::MessageSender
class TestRule
  case
    when Rails.env.production?
      publishes_to :snort_local_rules_work
    when Rails.env.staging?
      publishes_to :snort_local_rules_stage_work
    else
      publishes_to :snort_local_rules_test_work
  end



  def self.send_work_msg(task, xmlrpc_token, bug)
    # be sure to collect all the attachments too but only the ones that are pcaps
    all_attachments = bug.attachments.inject([]) do | memo, attachment |
      memo << attachment.id if /^[-\w]+.pcap$/.match(attachment.file_name)
      memo
    end

    rules_content = []
    task.rules.each do |rule|
      rules_content << rule.test_rule_content
    end
    case
      when Rails.env.production?
        publish :snort_local_rules_work,
                {
                    task_id: task.id,
                    cookie: xmlrpc_token,
                    pcaps: all_attachments,
                    rules: rules_content
                }.to_json
      when Rails.env.staging?
        publish :snort_local_rules_stage_work,
                {
                    task_id: task.id,
                    cookie: xmlrpc_token,
                    pcaps: all_attachments,
                    rules: rules_content
                }.to_json
      else
        publish :snort_local_rules_test_work,
                {
                    task_id: task.id,
                    cookie: xmlrpc_token,
                    pcaps: all_attachments,
                    rules: rules_content
                }.to_json
    end

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

