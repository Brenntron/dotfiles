#!/usr/bin/env rails runner
# USAGE: rails runner synch_rules.rb
# parses rules from stdin and loads into synched_rules table.

begin
  Rule.connection
  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: example.rb [options]"

    opts.separator ""
    opts.separator "Specific options:"

    opts.on("-s", "--[no-]status", "Print load status character") do |load_status|
      options[:load_status] = load_status
    end

    opts.on("-h", "-?", "--help", "--opts", "Help") do |help|
      puts opts
      exit
    end
  end.parse!

  $stdin.each_line do |line|
    begin
      rule = Rule.load_grep(line.chomp)
      case
        when rule.nil?
          $stdout.print "!"
          $stderr.puts line.chomp
        when options[:load_status]
          $stdout.print rule.load_status
        else
          $stdout.print "."
      end
    rescue
      $stderr.puts "cannot parse :#{line}"
      raise
    end
  end

  puts "done"
end

