#!/usr/bin/env ruby

ActiveRecord::Base.establish_connection(ENV['RAILS_ENV'])

# This script will complete any job with a timeout error if it has exceeded the configured timeout
while sleep(15)
	Job.where('completed = false and created_at < ?', Time.now.utc - Rails.configuration.job_timeout).each do |job|
		job.completed = true
		job.failed = true
		job.result = "Job timed out after #{Rails.configuration.job_timeout} seconds. Please try again."
		job.save
	end
end
