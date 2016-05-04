#!/usr/bin/env ruby

require 'stomp'
require 'json'
require 'tmpdir'
require 'tempfile'
require 'net/ssh'

# Limit the amount of memory used by a single client (300MB)
Process.setrlimit(:AS, 300 * 1024 * 1024)

# Use this for differentiating script errors instead of commit errors
class CommitError < RuntimeError; end

# Make sure we run from the application root
Dir.chdir ENV['APP_ROOT']

# General options
local_cache_path = File.expand_path('tmp/commit')
rules_cvs_path = 'sfeng/research/rules/snort-rules'
cvs_host='scm.sfeng.sourcefire.com'
cvs_command_template = "cvs -d USER@#{cvs_host}:/usr/cvsroot"

# Make sure our pcaps cache exists
if not File.exists?(local_cache_path)
	Dir.mkdir(local_cache_path)
end

stomp_options = {}
case Rails.env
  when "production"
    puts "stomp in production"
    stomp_options = {
        :hosts => [{:login => "guest", :passcode => "guest", :host => 'mqtest01.vrt.sourcefire.com', :port => 61613, :ssl => false}],
        :reliable => true, :closed_check => false
    }
  when "staging"
    puts "stomp in staging"
    stomp_options = {
        :hosts => [{:login => "guest", :passcode => "guest", :host => 'mqtest01.vrt.sourcefire.com', :port => 61613, :ssl => false}],
        :reliable => true, :closed_check => false
    }
  when "development"
    puts "stomp in development"
    stomp_options = {
        :hosts => [{:login => "guest", :passcode => "guest", :host => 'localhost', :port => 61613, :ssl => false}],
        :reliable => true, :closed_check => false
    }
end

# Create our stomp client
client = Stomp::Connection.new(stomp_options)

# This queue should only have work jobs for local rule runs
client.subscribe "/queue/RulesUI.Snort.Commit.Work", { :ack => :client }

# Begin receiving messages
while message = client.receive

	begin

		# We need the start time for our cvs diff
		start_time = (Time.now - 15).strftime("%Y-%m-%d %H:%M:%S")

		# Start by parsing the request
		request = JSON.parse(message.body)
		puts request.inspect

		# Make sure we have everything we are going to need
		if request['cookie'].nil?
			raise CommitError.new("cookie not sent")
		end
		if request['rules'].nil? or request['rules'].empty?
			raise CommitError.new("no bugs sent to commit")
		end
		if request['task_id'].nil?
			raise CommitError.new("no task_id sent in this request")
		end
		if request['bug_id'].nil?
			raise CommitError.new("no bug_id sent in this request")
		end

		if request['cvs_username'].nil?
			raise CommitError.new("no cvs_username sent in this request")
		else
			cvs_command = cvs_command_template.gsub(/USER/, request['cvs_username'])
		end

		# Make sure we can ssh to the cvs host
		Net::SSH.start(cvs_host, request['cvs_username']) do |ssh|
			if ssh.exec!('uname -a') !~ /(FreeBSD|Linux)/
				raise CommitError.new("uname response invalid")
			end
		end

		# Start by creating a temporary directo to work in
		Dir.mktmpdir("#{local_cache_path}/local-") do |dir|

			# Save this for later
			rule_path = "#{dir}/rules"

			# We should work inside of our temp directory
			Dir.chdir(dir)

			# Check out the current rules
			result = `#{cvs_command} co -d rules -l #{rules_cvs_path} 2>&1`
			unless $?.exitstatus == 0
				raise CommitError.new("Failed to checkout snort rules: #{result}")
			end

			# Fix up each rule before attempting to commit
			request['rules'].each do |rule|

				# Comment out any rules not in balanced or higher
				if rule['content'] !~ /policy (balanced-ips|connectivity-ips)/
					if rule['content'] !~ /flowbits\s*:\s*set\s*,/
						rule['content'].gsub!(/^alert/, '# alert')
					end
				end

				# Extract the rule file (category)
				if rule['content'] =~ /\(\s*?msg:"(\S+)/
					rule['category'] = $1.downcase
				else
					raise CommitError.new("Unable to find category: #{rule['category']}")
				end

				# Open the rules file to work with
				rule_category_path = "#{rule_path}/#{rule['category']}.rules"

				# If new, we can just append to the end.  Otherwise, we need to insert into the existing location
				if rule['sid'].nil?
					# Read the entire file into an array
					lines = File.open(rule_category_path, "r").each_line.to_a.map {|l| l.chomp}

					# Add our new line to the array
					lines << rule['content'].chomp

					# Now we should write the file back out
					File.open(rule_category_path, 'w+') {|f| f.write(lines.join("\n") + "\n")}
				else
					# Read the entire file into an array
					lines = File.open(rule_category_path, "r").each_line.to_a.map {|l| l.chomp}

					# Find our rule line
					matches = File.open(rule_category_path, "r").each_line.grep(/\s+sid:#{rule['sid']};/)

					# Make sure something isn't very wrong
					if matches.empty?
						raise CommitError.new("Unable to find #{rule['content']} in #{rule['category']}.rules.  Did the category change?")
					end

					# There should only be one match
					if matches.size != 1
						raise CommitError.new("Multiple matching rules found in #{rule['category']} for #{rule['content']}")
					end

					# Now find our line number
					line = lines.index(matches.first.chomp)

					# Make sure we are still sane
					if line.nil?
						raise CommitError.new("Could not find line number for #{rule['content']} in #{rule['category']}")
					end

					# Make sure the revs match before continuing
					if matches.first !~ /\s+rev:(\d+);/
						raise CommitError.new("Unable to find revision in existing rule #{matches.first}")
					end

					# Finally insert the new rule into the array
					lines[line] = "#{rule['content']}".chomp

					# Now we should write the file back out
					File.open(rule_category_path, 'w+') {|f| f.write(lines.join("\n") + "\n")}

				end
			end

			# Time to commit our rule changes
			Dir.chdir('rules')
			result = `#{cvs_command} commit -m 'Updating rules for bug #{request['bug_id']}' 2>&1`
			unless $?.exitstatus == 0
				raise CommitError.new("Error committing changes: #{result}")
			end

			# Remove the old files
			Dir.glob('*.rules') {|f| File.delete(f) }

			# Now cvs update for comparison
			tmp_result = `#{cvs_command} update 2>&1`
			unless $?.exitstatus == 0
				raise CommitError.new(tmp_result)
			end

			# Get diff of our changes
			end_time = (Time.now + 15).strftime("%Y-%m-%d %H:%M:%S")
			diff = `#{cvs_command} diff -D"#{start_time}" -D"#{end_time}" 2>&1`

			# Make sure we got a diff back
			raise CommitError.new("Unable to get diff after commit") if diff.nil?

			# Send back a list of all rule changes
			rules = Array.new	

			# Parse all of the changes in the diff
			diff.scan(/^> (?:# )?(.*)/) do |match|
				rules << match[0]
			end

			# And notify the front end that the job is complete
			client.publish "/queue/RulesUI.Snort.Commit.Test.Result",
				{ :task_id => request['task_id'], :completed => true, :failed => false, :result => result, :rules => rules, :cookie => request['cookie'] }.to_json

		end

	rescue SocketError, Errno::EHOSTUNREACH, Net::SSH::Disconnect => e
		client.publish "/queue/RulesUI.Snort.Commit.Test.Result",
			{ :task_id => request['task_id'], :completed => true, :failed => true, :result => "Network failure: #{e.to_s}@#{cvs_host}"}.to_json
	
	rescue Net::SSH::AuthenticationFailed => e
		client.publish "/queue/RulesUI.Snort.Commit.Test.Result",
			{ :task_id => request['task_id'], :completed => true, :failed => true, :result => "Authentication failed for #{e.to_s}@#{cvs_host}"}.to_json

	rescue CommitError => e
		client.publish "/queue/RulesUI.Snort.Commit.Test.Result",
			{ :task_id => request['task_id'], :completed => true, :failed => true, :result => e.to_s}.to_json
	end

	# Finally let the server release this message
	client.ack(message.headers['message-id'])

end
