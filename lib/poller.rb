#!/usr/bin/env ruby
require 'syslog/logger'
# Limit the amount of memory used by a single client (300MB)
# Process.setrlimit(:AS, 1024 * 1024 * 1024)

# Make sure stdout and stderr write out without delay for using with daemon like scripts
STDOUT.sync = true; STDOUT.flush
STDERR.sync = true; STDERR.flush

ActiveMessaging.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'analyst-console-poller')

if ENV["RAILS_LOG_TO_STDOUT"].present?
  Rails.logger = Logger.new(STDOUT)
  ActiveMessaging.logger = Rails.logger
end

# Load ActiveMessaging
ActiveMessaging::load_processors

# Start it up!
ActiveMessaging::start