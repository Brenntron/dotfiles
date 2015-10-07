require 'activemessaging/processor'
include ActiveMessaging::MessageSender

class PublishWebsocket
  publishes_to :snort_local_rules_test_work

  def self.send_test_msg(message,request)
    publish :snort_local_rules_test_work, {
        :job_id => 1,
        :cookie => request.headers['Xmlrpc-Token'],
        :message => message
    }.to_json
  end


end