#!/usr/bin/env ruby

# Limit the amount of memory used by a single client (300MB)
Process.setrlimit(:AS, 1024 * 1024 * 1024)

# Make sure stdout and stderr write out without delay for using with daemon like scripts
STDOUT.sync = true; STDOUT.flush
STDERR.sync = true; STDERR.flush


Rails.logger = Logger.new(STDOUT)
ActiveMessaging.logger = Rails.logger

# Load ActiveMessaging
ActiveMessaging::load_processors

# Start it up!
ActiveMessaging::start
