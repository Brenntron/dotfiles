require 'activemessaging/processor'
include ActiveMessaging::MessageSender
class TestAttachment
  publishes_to :snort_all_rules_test_work

  def self.send_work_msg(content, xmlrpc_token, attachments)
    publish :snort_all_rules_test_work,
            {
              task_id: content.id,
              cookie: xmlrpc_token,
              pcaps: attachments
            }.to_json
  end

  def initialize(new_task, xmlrpc_token, attachments)
    @xmlrpc_token = xmlrpc_token
    @new_task = new_task
    @attachments = attachments
  end

  def send_work_msg
    @attachments.each do |attachment_id|
      attachment = Attachment.where(id: attachment_id).first
      Alert.reset_pcap(attachment)
      if /^[-\w]+.pcap$/.match(attachment.file_name)
        @new_task.attachments << attachment
      end
    end
    TestAttachment.send_work_msg(@new_task, @xmlrpc_token, @attachments)
  end
end
