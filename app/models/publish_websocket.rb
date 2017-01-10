require 'activemessaging/processor'
require 'json'
include ActiveMessaging::MessageSender

class PublishWebsocket
  publishes_to :snort_local_rules_test_work

  def self.push_changes(record)
    publish :snort_local_rules_test_work,
            {record: record.to_json}.to_json
  end
end
