require 'activemessaging/processor'
include ActiveMessaging::MessageSender
class PublishRule
  publishes_to :snort_local_rules_test_work

  def self.send_work_msg(content, options, xmlrpc_token)
    # be sure to collect all the attachments too but only the ones that are not obsolete
    all_attachments = options[:bug].attachments.map { |b| b.is_obsolete ? next : b.id }.reject { |v| v.nil? }
    # TODO: collect rule content to insert in the local_rules. Dont use numbers.
    rules_content = []
    content.rules.each do |rule|
      rules_content << rule.rule_content
    end
    publish :snort_local_rules_test_work,
            {
              task_id: content.id,
              cookie: xmlrpc_token,
              attachments: all_attachments,
              rules: rules_content
            }.to_json
  end
end

