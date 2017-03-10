 class SnortLocalRulesResultProcessor < ApplicationProcessor

  subscribes_to :snort_local_rules_test_result

  def on_message(message)
    puts "=============================="
    puts "Configuring local rule results"
  	result = JSON.parse(message)

  	attachment = Attachment.find_by_bugzilla_attachment_id(result['id'])

    # Is this an alert message or a job completion message?
    if result['completed'] and result['task_id']
    	job = Task.find(result['task_id'])
      job.result = result['result']
    	job.completed = true
      job.failed = result['failed']
    	job.save

      # Nothing to do on a failed job
      return if job.failed

      # Parse performance results (as Donald Knuth would approve)
      job.update_rule_stats

    else
      if result['sid'].to_i > 1000000
        rule = Rule.find_by_id(result['sid'].to_i - 1000000)
      else
		    rule = Rule.find_by_sid(result['sid'])
      end

      # Watch out for preproc and file-identify rules in alerts
      unless rule.nil?
        begin 
          rule.attachments << attachment
        rescue ActiveRecord::RecordNotUnique => e
          # Ignore
        end

    	  rule.save
      end
    end
  end
end
