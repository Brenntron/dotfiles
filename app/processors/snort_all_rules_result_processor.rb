class SnortAllRulesResultProcessor < ApplicationProcessor

   subscribes_to :snort_all_rules_test_result

   def on_message(message)
     puts "============================"
     puts "Configuring all rule results"
      result = JSON.parse(message)	

      unless result['job_id'].nil?

         begin
            # Make sure to close the job
            job = Task.find(result['task_id'])
            job.result ||= ""
            return if job.nil?

            attachments = Hash.new
            result['alerts'].each do |alert|
               attachments[alert['id']] ||= Array.new
               attachments[alert['id']] << alert
            end

		if result['errors'].size > 0
			job.failed = true

			result['errors'].each do |err|
				job.result << "#{err}\n"
			end
		end
            attachments.each do |attachment_id, alerts|
               attachment = Attachment.find_by_bugzilla_attachment_id(attachment_id)

               alerts.each do |alert|
                  begin
      		         rule = Rule.find_by_gid_and_sid(alert['gid'].to_i, alert['sid'].to_i)

                     if rule.nil?
                        if alert['gid'].to_i == 1
                           rule = Rule.new(:content => Rule.find_current_rule(alert['sid'].to_i))
                        else
                           rule = Rule.new(:gid => alert['gid'].to_i, :sid => alert['sid'].to_i, :rev => alert['rev'].to_i, :message => alert['message'])
                        end

                        rule.rule_state = RuleState.Unchanged
                     end

                     # The rule should have extracted if it was valid
                     if rule.valid?
                        rule.attachments << attachment 
                        rule.save(:validate => false)
                     else
                        if rule.message.nil?
                           job.failed = true
                           rule.errors.each do |k,v|
                              job.result << "#{rule.version} #{v}\n"
                           end
                        else
                           rule.attachments << attachment
                           rule.save(:validate => false)
                        end
                     end

                  rescue RuleError => e
                     job.failed = true
                     job.result << "#{e.to_s} for sid #{alert['sid']}\n"
                  rescue ActiveRecord::RecordNotUnique => e
                     # Ignore these
                  end
               end
            end

            job.completed = true
            job.save
         rescue Exception => e
            puts e.to_s
            puts e.backtrace.join("\n")
         end
      end
   end
end
