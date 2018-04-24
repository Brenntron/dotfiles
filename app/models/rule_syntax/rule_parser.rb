
# Parser to decompose elements of the string of a snort rule into fields for our database.
#
# This is our parser, in the sense that we are not calling a library maintained externally.
module RuleSyntax
  class RuleParser
    attr_reader :rule_content

    def initialize(rule_content)
      @rule_content = rule_content.chomp
    end

    def parse
      if /\A(?<connection>[^\(]*)\((?<options>.*)\)\s*\z/ =~ rule_content
        @connection = connection.strip
        @options = options
      end
    end

    def connection
      unless @connection
        parse
      end
      @connection
    end

    def options
      unless @options
        parse
      end
      @options
    end

    def well_formed?
      connection && options
    end

    def raw_hash
      unless @raw_hash
        raise "Cannot parser rule content '#{rule_content}'" unless options
        @raw_hash ||= options.split(/\s*;\s*/).inject({}) do |raw_hash, option|
          if /\A\s*(?<type>\w+)\s*:\s?(?<data>.*)\z/ =~ option
            key = type.downcase.to_sym
            raw_hash[:detection] ||= []
            case
              when %i(gid sid rev).include?(key)
                raw_hash[key] = data.to_i
              when %i(classtype metadata msg flow).include?(key)
                raw_hash[key] = data
                raw_hash[:class_type] = data if :classtype == key
              when %i(reference).include?(key)
                raw_hash[key] ||= []
                raw_hash[key] << data
              else
                raw_hash[:detection] << option
            end
          else
            raw_hash[:detection] << option
          end
          raw_hash
        end
      end

      @raw_hash
    end

    def detection_array
      @detection_array ||= raw_hash[:detection] || []
    end

    # Hash of rule parts
    # Keys are:
    #    :connection = socket tuple and direction
    #    :msg = rule category and message text
    #    :message = message text (without rule category)
    #    :rule_category = rule category [String]
    #    :flow
    #    :detection = [String]
    #    :metadata
    #    :reference = [Array<String>]
    #    :classtype
    #    :gid
    #    :sid
    #    :rev
    # @return [Hash]
    def attributes
      @attributes ||= raw_hash.clone.tap do |attributes|
        attributes[:connection] = connection
        attributes[:gid] ||= 1
        attributes[:detection] = detection_array.map{|det| "#{det};"}.join(" ")

        msg = attributes[:msg]
        if msg
          if (/\A\s*"/ =~ msg) && (/"\s*\z/ =~ msg)
            msg.gsub!(/\A\s*"/, '').gsub!(/"\s*\z/, '')
          end
          if (/\A\s*'/ =~ msg) && (/'\s*\z/ =~ msg)
            msg.gsub!(/\A\s*'/, '').gsub!(/'\s*\z/, '')
          end

          if /\A(?<category>[-\w]+)\s(?<message>.*)\z/ =~ msg
            attributes[:rule_category] = category
            attributes[:message] = msg
          end
        end
      end
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
  end
end
