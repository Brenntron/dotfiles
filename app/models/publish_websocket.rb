require 'activemessaging/processor'
require 'json'
include ActiveMessaging::MessageSender

class PublishWebsocket
  case
    when Rails.env.production?
      publishes_to :snort_local_rules_work
    when Rails.env.staging?
      publishes_to :snort_local_rules_stage_work
    else
      publishes_to :snort_local_rules_test_work
  end

  def self.push_changes(record)
    case
      when Rails.env.production?
        publish :snort_local_rules_work,
                {record: record.to_json}.to_json
      when Rails.env.staging?
        publish :snort_local_rules_stage_work,
                {record: record.to_json}.to_json
      else
        publish :snort_local_rules_test_work,
                {record: record.to_json}.to_json
    end

  end
end
