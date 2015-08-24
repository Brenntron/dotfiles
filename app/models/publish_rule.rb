require 'activemessaging/processor'
include ActiveMessaging::MessageSender
class PublishRule
  publishes_to :snort_local_rules_test_work

  def self.send_work_msg(content,options,request)
    rules = []
    #be sure to collect all the rules to test here.
    publish :snort_local_rules_test_work, {
        :job_id => content.id,
        :cookie => request.headers['Xmlrpc-Token'],
        :attachments => options[:attachment_array].split(",").map { |s| s.to_i },
        :rules => rules
    }.to_json
  end

end
