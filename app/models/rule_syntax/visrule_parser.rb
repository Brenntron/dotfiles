
# Parser for calling the visruleparser perl script.
#
# The visruleparser perl script is not intended for parsing exactly.
# That is, it was not written to break the snort rule syntax into component values
# which we want to store in our database.
# Really it should be named rule checker, since it screens rules and presents human readable
# output to alert analysts for obvious deficiencies in the rule they wrote.
#
# Instances of this class call the visruleparser perl script to get its output
# to show to analysts in our application.
module RuleSyntax
  class VisruleParser
    attr_reader :rule_content

    def initialize(rule_content)
      @rule_content = rule_content
    end

    def parse
      return nil if @rule_content.empty?
      temp_rule = Tempfile.new('temp.rules')
      temp_rule.write(@rule_content)
      temp_rule.rewind
      cmd = "#{Rails.configuration.perl_cmd} #{Rails.configuration.visruleparser_path} #{temp_rule.path}"
      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        @exit_status = wait_thr.value.exitstatus
        @stderr = stderr.read
        text = stdout.read
        if text.empty?
          @parsed_lines = ''
          @errors = ''
        else
          @parsed_lines = text.split(/%{80}|\*{80}/)[1].strip
          @errors = text.split(/%{80}|\*{80}/)[2] ? text.split(/%{80}|\*{80}/)[2].gsub('%', '').strip : ''
        end
      end
      temp_rule.close

      @parsed_lines
    end

    def parsed_lines
      unless @parsed_lines
        parse
        if fatal_errors
          @parsed_lines = 'FAILED: visruleparser error.'
        end
      end
      @parsed_lines
    end

    def errors
      unless @errors
        parse
      end
      @errors
    end

    def stderr
      unless @stderr
        parse
      end
      @stderr
    end

    # Positive integer for least significant 8 bits of UNIX process exit status.
    # So, when visruleparser fails, as from a perl error (possibly syntax or some unexpected condition)
    # the `exit -1` returns 255 from UNIX.
    # When visruleparser deliberately indicates a failure, it uses exit status -2,
    # which we get a 254 from UNIX.
    def exit_status
      unless @exit_status
        parse
      end
      @exit_status
    end

    def fatal_errors
      # We expected the exit status to be 8 bit unsigned,
      # but just in case the input does not match our expectations,
      # make sure our output does.
      255 == (exit_status & 0x0FF) ? stderr : nil
    end

    # @return [Boolean] false if this class rejected the string as not even content
    def has_rule_content?
      !!parse
    end

    # Is enough in the snort rule format for visruleparser to recognize it as a rule.
    #
    # Some strings (particularly comment lines in snort rule files) do fit proper snort rule syntax,
    # that visruleparser rejects them without attempting to parse it as a rule.
    # When visruleparser does so, it prepends the line number or 1: (since we only do one line it is always 1)
    # to the rule and writes it to stdout.
    # There are no errors in this case, so stderr is empty.
    # When visrule does parse the line, there is a Message section, unlike the msg key in the rule syntax.
    # The Message key will always be at the beginning of a line (ignoring whitespace) followed by a colon.
    # @return [Boolean] true if visruleparser recogizes it as a rule, and false if it does not.
    def is_a_rule?
      # /^\s*Message\s*:/ =~ parsed_lines
      # errors.empty? #empty string
      # /^\d+:/ !~ parsed_lines
      !!(/^\s*Message\s*:/ =~ parsed_lines)
    end

    def valid?
      # skips if @valid is false
      if @valid.nil?

        @valid =
            case
              # this ruby class rejected the rule content before even calling visrule parser
              when !has_rule_content?
                false

              # visruleparser had an error
              when stderr.present?
                false

              # visruleparser rejected the string as not enough like a snort rule to even parse
              when !is_a_rule?
                false

              # visruleparser returned FAIL, FAILED, or FAILURES
              when /FAIL/ =~ parsed_lines
                false

              # visruleparser returned FAIL, FAILED, or FAILURES in stderr which is more logical than stdout
              when /FAIL/ =~ errors
                false

              else
                true
            end
      end
      @valid
    end

    def all_clear?
      case
        # this ruby class rejected the rule content before even calling visrule parser
        when !has_rule_content?
          false

        # visruleparser rejected the string as not enough like a snort rule to even parse
        when !is_a_rule?
          false

        # visruleparser returned FAIL, FAILED, or FAILURES
        when /FAIL/ =~ parsed_lines
          false

        # visruleparser returned FAIL, FAILED, or FAILURES in stderr which is more logical than stdout
        when /FAIL/ =~ errors
          false

        when /WARN/ =~ parsed_lines
          false

        when /WARN/ =~ errors
          false

        else
          true
      end
    end

    def parsed_hash
      @parsed_hash ||= parsed_lines.each_line.inject({}) do |parsed_hash, line|
        if /\A\s*(?<key>\w+)\s*:\s?(?<value>.*[\S])\s*\z/ =~ line
          parsed_hash[key.downcase.to_sym] = value
        end
        parsed_hash
      end
    end

    def gid
      parsed_hash[:gid] ? parsed_hash[:gid].to_i : 1
    end

    def sid
      # sid could be nil for a new rule
      parsed_hash[:sid] && parsed_hash[:sid].to_i
    end

    def rev
      parsed_hash[:rev] && parsed_hash[:rev].to_i
    end
  end
end

