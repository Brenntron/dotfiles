require 'activemessaging/processor'
require 'json'
include ActiveMessaging::MessageSender

class PublishWebsocket

  publishes_to Rails.configuration.amq_snort_local

  def self.push_changes(record)
    publish Rails.configuration.amq_snort_local,
            {record: record.to_json}.to_json
  end
end
