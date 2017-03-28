class SnortCommitResultProcessor < ApplicationProcessor

  subscribes_to :snort_commit_test_result

  def on_message(message)
    puts "=========================="
    puts "Configuring commit results"
    begin
    	response = JSON.parse(message)	
      xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)  
      xmlrpc.token = response['cookie']
      new_sids = []

      # Start by updating the job
    	job = Task.find(response['task_id'])
    	job.completed = response['completed']
    	job.failed = response['failed']
    	job.result = response['result']

      unless job.failed
        updated_rules = Array.new
        new_rules = Array.new

        # Update the internal rules for the updated rules
        response['result'].scan(/Updated\s+rule\s+sid:\s+(\d+)\s+rev:\s+(\d+)/) do |match|
          rule = Rule.find_by_sid(match[0].to_i)
          next if rule.nil?
          next unless job.rules.include?(rule)

          # Update the rev to the new revision
          rule.rev = match[1].to_i

          # We should have received the changed rules
          unless response['rules'].empty?

            # Find this rule in the updates
            response['rules'].each do |content|
              if content =~ /sid:#{rule.sid};/
                updated_rules << content
                rule.content = content
                break
              end
            end
          end

          # Rule state should be updated
          rule.state = "UNCHANGED"

          # Finally save our rule update
          rule.save(:validate => false)
        end

        # Now we need to match up the new rules
        response['result'].scan(/New\s+rule\s+sid:\s+(\d+)/) do |match|
          next if response['rules'].empty?

          # Find the new rule in the list of rules
          new_rule = nil          
          response['rules'].each do |content|
            if content =~ /sid:#{match[0]};/
              new_rule = content.to_s
              new_rules << new_rule
              break
            end
          end

          # Bail if the change wasn't found
          next if new_rule.nil?

          # The content of the rules should match up if we remove the sid
          rule = Rule.find_by_content(new_rule.gsub(/\s*sid:\d+;\s*/, '').gsub(/\s*rev:\d+;\s*/, ''))

          # Hopefully we found a our rule
          next if rule.nil?
          next unless job.rules.include?(rule)

          # Update the sid, rev, and content of the rule 
          rule.sid = match[0]
          rule.rev = 1
          rule.content = new_rule
          rule.state = "UNCHANGED"
          rule.save

          # Keep track of the new sids
          new_sids << rule.sid

        end

        # This is stupid
        result = job.result

        # Add updated rules to the report
        if updated_rules.size > 0
          result = result + "\nUpdated Rules:\n"
          updated_rules.each do |rule|
            result = result + "\t#{rule}\n"
          end
        end

        # Add new rules to the report
        if new_rules.size > 0
          result = result + "\nNew Rules:\n"
          new_rules.each do |rule|
            result = result + "\t#{rule}\n"
          end
        end
        
        # Make sure we update the result before sending our report
        job.result = result

        # Update the bug
        job.bug.refresh_summary(xmlrpc)
        job.bug.close(xmlrpc, job.commit_report)
        job.bug.bugzilla_summary_sids_add(xmlrpc, new_sids)
        job.bug.save

        # Save any last changes
        job.save

      else
        # The job failed so there is nothing to do
        job.save
      end

    rescue Exception => e
        puts e.to_s     
        puts e.backtrace.join("\n")     
        job.failed = true 
        job.result = job.result + "\nError while parsing commit response: #{e.to_s}"   
        job.save
    end

    # Make sure we update the rules
    publish :snort_commit_reload, { :reload_so => false }.to_json
  end
end
