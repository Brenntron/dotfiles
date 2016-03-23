require 'activemessaging/processor'
include ActiveMessaging::MessageSender
class PublishAttachment
  publishes_to :snort_all_rules_test_work

  def self.send_work_msg(content,options,request)
    publish :snort_all_rules_test_work, {
        :local_job_id => content.id,
        :cookie => request.headers['Xmlrpc-Token'],
        :attachments => options[:attachment_array].split(",").map { |s| s.to_i }
    }.to_json
  end


end