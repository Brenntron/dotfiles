require 'activemessaging/processor'
include ActiveMessaging::MessageSender
class Publish
  publishes_to :snort_local_rules_test_work

  def self.send_work_msg(content,options,request)

    publish :snort_local_rules_test_work, {
        :test_message => "hoooray this works!",
        :job_id => content.id,
        :cookie => request.headers['Xmlrpc-Token'],
        :attachments => options[:attachment_array]
    }.to_json

  end


end