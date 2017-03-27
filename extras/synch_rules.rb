#!/usr/bin/env rails runner
# USAGE: rails runner synch_rules.rb
# parses rules from stdin and loads into synched_rules table.

begin
  Rule.connection

  $stdin.each_line do |line|
    begin
      if Rule.load_grep(line.chomp)
        $stdout.print "."
      else
        $stdout.print "F"
        $stderr.puts line.chomp
      end
    rescue
      $stderr.puts "cannot parse :#{line}"
      raise
    end
  end

  puts "done"
end

