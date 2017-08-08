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

  #We only want to send attachment ids to self.send_work_msg that are actual pcap files
  #so run regex on attachment filename, if it matches pcap, then put it into pcap_attachment_ids
  #send pcap_attachment_ids to self.send_work_msg
  def send_work_msg
    pcap_attachment_ids = []
    @attachments.each do |attachment_id|
      attachment = Attachment.where(id: attachment_id).first
      Alert.reset_pcap(attachment)
      if /^[-\w]+.pcap$/.match(attachment.file_name.downcase)
        @new_task.attachments << attachment
        pcap_attachment_ids << attachment_id
      end
    end
    TestAttachment.send_work_msg(@new_task, @xmlrpc_token, pcap_attachment_ids)
  end
end
