
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

    def raw_hash
      unless @raw_hash
        @raw_hash ||= options.split(/\s*;\s*/).inject({}) do |raw_hash, option|
          if /\A\s*(?<type>\w+)\s*:\s?(?<data>.*)\z/ =~ option
            key = type.downcase.to_sym
            case
              when %i(gid sid rev).include?(key)
                raw_hash[key] = data.to_i
              when %i(classtype metadata msg flow).include?(key)
                raw_hash[key] = data
                raw_hash[:class_type] = data if :classtype == key
              else
                raw_hash[key] ||= []
                raw_hash[key] << data
            end
          end

          raw_hash
        end
      end

      @raw_hash
    end

    def detection
      raw_hash[:content].map{|body| "content: #{body};"}.join
    end

    def attributes
      @attributes ||= raw_hash.tap do |attributes|
        attributes[:connection] = @connection
        attributes[:gid] ||= 1
        attributes[:detection] = detection

        if (msg = attributes[:msg])
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
