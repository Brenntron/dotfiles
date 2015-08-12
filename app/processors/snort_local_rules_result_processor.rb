class SnortLocalRulesResultProcessor < ApplicationProcessor

  subscribes_to :snort_local_rules_test_result

  def on_message(message)
  	result = JSON.parse(message)	
  	attachment = Attachment.find_by_bugzilla_attachment_id(result['id'])

    # Is this an alert message or a job completion message?
    if result['completed'] and result['job_id']
    	job = Job.find(result['job_id'])
      job.result = result['result']
    	job.completed = true
      job.failed = result['failed']
    	job.save

      # Nothing to do on a failed job
      return if job.failed
      
      begin

        # Parse performance results (Please lord forgive me)
        stats = Hash.new
        job.result.each_line.to_a.map {|l| l.split(/\s+/)}.delete_if {|a| a[1] !~ /\d+/}.map { |a| [a[2], a[3], a[4], a[9], a[10], a[11] ] }.each do |a|
          stats[a[0].to_i] = [a[3].to_f, a[4].to_f, a[5].to_f]
        end

        # Update each rule in the 
        job.bug.rules.find(:all, :conditions => ['gid = ?', 1]).each do |rule|
          unless stats[rule.temp_sid].nil?
            rule.average_check = stats[rule.temp_sid][0]
            rule.average_match = stats[rule.temp_sid][1]
            rule.average_nonmatch = stats[rule.temp_sid][2]
            rule.save
          end
        end

      rescue Exception => e
        # We don't care if this fails
      end

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
