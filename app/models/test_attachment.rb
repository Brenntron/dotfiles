require 'activemessaging/processor'
include ActiveMessaging::MessageSender
class TestAttachment
  publishes_to :snort_all_rules_test_work

  def self.send_work_msg(content, options, xmlrpc_token)
    publish :snort_all_rules_test_work,
            {
              task_id: content.id,
              cookie: xmlrpc_token,
              attachments: options[:attachment_array]
            }.to_json
  end
end
