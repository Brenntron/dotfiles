
# A reassembler of elements of a snort rule into correct snort rule syntax.
#
# A combination of assembler and composer,
# this may take components from the web form or from the fields in our database
# and build the string line for a snort rule.
module RuleSyntax
  class Assemposer
    attr_reader :rule_params, :conn_params

    def initialize(rule_params)
      @rule_params = rule_params
      @conn_params = rule_params['connection'] if rule_params['connection']
    end

    def connection
      @connection ||=
          case conn_params
            when NilClass
              nil
            when String
              conn_params
            when Hash
              %w(action protocol src srcport direction dst dstport).map{|key| conn_params[key]}.join(' ')
          end
    end

    # @return [RuleCategory]
    def rule_category
      @rule_category ||=
          case
            when rule_params['rule_category_id']
              RuleCategory.where(id: rule_params['rule_category_id']).first
            when rule_params['rule_category']
              RuleCategory.where(category: rule_params['rule_category']).first
            else
              nil
          end
    end

    def message
      unless @message
        @message = rule_params['message'] || ''
        @message =
            case
              when /\A'(?<new_message>.*)'\z/ =~ @message
                new_message
              when /\A"(?<new_message>.*)"\z/ =~ @message
                new_message
              else
                @message
            end
      end
      @message
    end

    def msg
      @msg ||=
          case
            when rule_params['msg'].present?
              rule_params['msg']
            when message.present?
              "#{rule_category.category if rule_category} #{message}"
          end
    end

    def attributes
      rule_params.to_h.slice(*%w(sid gid rev class_type detection flow metadata references)).merge(
          connection: connection,
          rule_category: rule_category ? rule_category.category : nil,
          message: msg,
      )
    end

    def options
      unless @options
        options_ary = []
        options_ary << "msg:\"#{msg}\";" if msg.present?
        options_ary = %w(sid rev flow metadata).inject(options_ary) do |ary, key|
          ary << "#{key}:#{attributes[key]};" if attributes[key].present?
          ary
        end
        if attributes['gid'] && 1 != attributes['gid']
          ary << "#{key}:#{attributes[key]};" if attributes[key].present?
        end
        options_ary = %w(detection references).inject(options_ary) do |ary, key|
          ary << attributes[key] if attributes[key]
          ary
        end
        options_ary << "classtype:#{attributes['class_type']};" if attributes['class_type'].present?
        @options = options_ary.join(' ')
      end
      @options
    end

    def rule_content
      "#{connection} (#{options})"
    end

    def gid
      rule_params[:gid] || rule_params['gid'] || 1
    end

    def sid
      rule_params[:sid] || rule_params['sid']
    end

    def rev
      rule_params[:rev] || rule_params['rev']
    end
  end
end
