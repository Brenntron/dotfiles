require 'activemessaging/processor'
require 'json'
include ActiveMessaging::MessageSender

class PublishWebsocket
  publishes_to :snort_local_rules_test_messages

  def self.push_changes(record)
    publish :snort_local_rules_test_messages, {
        :record => record.to_json
    }.to_json
  end

end