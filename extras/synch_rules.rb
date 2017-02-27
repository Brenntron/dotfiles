#!/usr/bin/env rails runner
# USAGE: rails runnersynch_rules.rb
# parses rules from stdin and loads into synched_rules table.

$stdin.each_line do |line|
  Rule.load_rule(line.chomp)
  $stdout.print "."
end

