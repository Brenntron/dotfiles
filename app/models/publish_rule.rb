require 'activemessaging/processor'
include ActiveMessaging::MessageSender
class PublishRule
  publishes_to :snort_local_rules_test_work

  def self.send_work_msg(content,options,request)
    #be sure to collect all the attachments too but only the ones that are not obsolete
    all_attachments = options[:bug].attachments.map { |b| b.is_obsolete ? next : b.id}.reject() { |v| v.nil? }
    publish :snort_local_rules_test_work, {
        :local_job_id => content.id,
        :cookie => request.headers['Xmlrpc-Token'],
        :attachments => all_attachments,
        :rules => options[:rule_array].split(",").map { |s| s.to_i }
    }.to_json
  end

end
