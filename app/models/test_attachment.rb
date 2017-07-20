require 'activemessaging/processor'
include ActiveMessaging::MessageSender
class TestAttachment

  publishes_to Rails.configuration.amq_snort_all


  def self.send_work_msg(content, xmlrpc_token, attachments)
    publish Rails.configuration.amq_snort_all,
            {
                task_id: content.id,
                cookie: xmlrpc_token,
                pcaps: attachments
            }.to_json
  end

  def initialize(new_task, xmlrpc_token, attachments)
    @xmlrpc_token = xmlrpc_token
    @new_task = new_task
    @attachments = attachments.map { |attachment_id| attachment_id.to_i }
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
