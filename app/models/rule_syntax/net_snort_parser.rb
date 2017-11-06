module RuleSyntax
  class NetSnortParser
    attr_reader :json, :parsed

    # Escape for command line
    def self.cmd_esc(str)
      # Need backslash + character in output
      # gsub argument needs to escape backslash + backslash 1 for first regexp capture
      # Need to escape the backslashes in the ruby string literal
      # str.gsub(/([$"'\(\);])/, '\\\\\\1')
      str.gsub(/([$"])/, '\\\\\\1')
    end

    def initialize(json)
      @json = json
      @parsed = JSON.parse(@json)
    end

    def self.new_from_json(json)
      new(json)
    end

    def self.new_from_json_lines(output)
      output.split("\n").map do |line|
        new_from_json(line)
      end
    end

    def self.new_from_rule_content(rule_content)
      cd_cmd = "cd #{Rails.configuration.extras_dir}"
      cmd_line = "echo \"#{cmd_esc(rule_content)}\" | #{Rails.configuration.perl_cmd} #{Rails.configuration.snort_json_path}"
      output = `#{cd_cmd};#{cmd_line}`
      new_from_json_lines(output).first
    end

    def self.new_from_filename(filename)
      cd_cmd = "cd #{Rails.configuration.extras_dir}"
      output = `#{cd_cmd};#{Rails.configuration.perl_cmd} #{Rails.configuration.snort_json_path} #{filename}`
      new_from_json_lines(output)
    end

    def error?
      parsed.key?('error')
    end

    def error
      error? && parsed['error']
    end

    def connection
      "#{parsed['action']} #{parsed['protocol']}" +
          " #{parsed['src']} #{parsed['srcport']} #{parsed['direction']}" +
          " #{parsed['dst']} #{parsed['dstport']}"
    end

    def options
      unless @options
        @options = parsed['options'].values.inject({}) do |options, option|
          case option['type']
            when 'flow'
              options[:flow] = option['original']
            when 'flowbits'
              options[:flowbits] = option['args']
            else
              options[:detection_options] ||= []
              options[:detection_options] << option
          end
          options
        end
      end
      @options
    end

    def flows
      options[:flows]
    end

    # Hash of rule parts
    # Keys are:
    #    :connection = socket tuple and direction
    #    :msg = rule category and message text
    #    :message = message text (without rule category)
    #    :rule_category = rule category [String]
    #    :flow
    #    :classtype
    #    :gid
    #    :sid
    #    :rev
    #
    # NOTICE: Does not have :detection, :metadata or :reference.
    # @return [Hash]
    def attributes
      unless @attributes
        @attributes = options.slice(:flow, :flowbits)
        @attributes = %w{gid sid}.inject(@attributes) do |attributes, key|
          attributes[key.to_sym] = parsed[key].to_i
          attributes
        end
        @attributes[:rev] = parsed['revision'].to_i
        @attributes[:connection] = connection
        @attributes[:msg] =  parsed['name']
        if /\A(?<category>[-\w]+)\s(?<message>.*)\z/ =~ @attributes[:msg]
          attributes[:rule_category] = category
          attributes[:message] = message
        end
        @attributes[:classtype] =  parsed['classification']
    end
      @attributes
    end

    def gid
      attributes[:gid]
    end

    def sid
      attributes[:sid]
    end

    def rev
      attributes[:rev]
    end

    # Compares two detection option hashes for identity.
    #
    # Matches if both have the same keys, and all keys have the same value.
    # When the Hash returned from Net-Snort-Parser for the whole rule,
    # the 'options' section.  Those values, removing type flow and type flowbits.
    # An input hash is one of the remaining values.
    # This will be a hash of directives in one content group.
    #
    # @param [Hash] option_left one input hash
    # @param [Hash] option_right one input hash
    def option_same?(option_left, option_right)
      return false unless (option_left.keys - option_right.keys).empty?
      return false unless (option_right.keys - option_left.keys).empty?

      option_left.all? {|key, value| value == option_right[key]}
    end

    # Compares the detection options with the detection options of another parser.
    #
    # Matches if all the content blocks of directives match between the two parsers.
    # When the Hash returned from Net-Snort-Parser for the whole rule,
    # the 'options' section.  Those values, removing type flow and type flowbits.
    # The arrays of the remaining options are compared.
    #
    # @param [NetSnortParser] parser an other parser.
    def detection_match?(parser)
      self_options = options[:detection_options]
      other_options = parser.options[:detection_options].clone

      # optimized fast return
      return false unless self_options.count == other_options.count

      self_options.each do |self_option|
        other_option = other_options.find{ |option| option_same?(self_option, option) }
        return false unless other_option #match is false if self has option that other does not
        other_options.delete(other_option)
      end

      #match is false if other has option that self does not
      other_options.empty?
    end

    def metadata_match?(parser)
      self_metadata_hash = parsed['metadata']
      other_metadata_hash = parser.parsed['metadata']

      return true if self_metadata_hash.nil? && self_metadata_hash.nil?
      return false if self_metadata_hash.nil? || self_metadata_hash.nil?

      return false unless (self_metadata_hash.keys - other_metadata_hash.keys).empty?
      return false unless (other_metadata_hash.keys - self_metadata_hash.keys).empty?

      self_metadata_hash.each do |key, value|
        self_value = value.keys
        other_value = other_metadata_hash[key].keys
        return false unless (self_value - other_value).empty?
        return false unless (other_value - self_value).empty?
      end

      true
    end

    def match?(parser)
      return false if error?
      return false if parser.error?
      return false unless attributes[:connection] == parser.attributes[:connection]
      return false unless attributes[:msg] == parser.attributes[:msg]
      return false unless detection_match?(parser)
      return false unless attributes[:classtype] == parser.attributes[:classtype]
      return false unless attributes[:flow] == parser.attributes[:flow]
      return false unless metadata_match?(parser)
      true
    end

    def match!(parser)
      raise error if error?
      raise parser.error if parser.error?
      match?(parser)
    end
  end
end
