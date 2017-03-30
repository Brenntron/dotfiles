class RuleParser
  attr_reader :rule_content

  class Metadata
    def initialize(raw)
      @metadata_array =
          case raw
            when Hash
              raw.inject([]) do |metadata, (type, data)|
                metadata += data.keys.map{ |datum| {type: type.downcase.to_sym, data: datum} }
                metadata
              end
            when Array
              raw
            else
              []
          end
    end

    def to_a
      @metadata_array
    end

    def to_s
      @metadata_str ||= @metadata_array.map{ |elem| "#{elem[:type]} #{elem[:data]}" }.join(', ')
    end
  end

  def initialize(rule_content)
    @rule_content = rule_content
  end

  def parse
    return nil if @rule_content.empty?
    temp_rule = Tempfile.new('temp.rules')
    temp_rule.write(@rule_content.gsub(/\#\s/, ''))
    temp_rule.rewind
    Open3.popen3("#{Rails.configuration.visruleparser_path} struct #{temp_rule.path}") do |stdin, stdout, stderr, wait_thru|
      text = stdout.read
      unless text.empty?
        @parsed_lines = text.split(/%{80}|\*{80}/)[1].strip
        @errors = text.split(/%{80}|\*{80}/)[2] ? text.split(/%{80}|\*{80}/)[2].gsub('%', '').strip : ''
        @errors += stderr.read
      end
    end
    temp_rule.close

    @parsed_lines
  end

  def errors
    unless @errors
      parse
    end
    @errors
  end

  def parsed_lines
    unless @parsed_lines
      parse
    end
    @parsed_lines
  end

  def rubified
    @rubified ||= parsed_lines.each_line.inject([{}]) do |stack, line|
      line = line.chomp
      case
        # $VAR1 = {
        when (/\A\$\w+\s*=\s*\{\s*\z/ =~ line) && (1 == stack.length) && stack.first.empty?

        # 'key' => }
        when /\A\s*\}\s*,?\s*;?\s*\z/ =~ line
          unless 1 == stack.length
            hash, key = stack.shift(2)
            stack[0][key] = hash
          end

        when /\A\s*'(?<lhs>[^']+)'\s*=>\s*(?<rhs_comma>.*)\z/ =~ line
          key = (/^\d+$/ =~ lhs) ? lhs.to_i : lhs.downcase.to_sym

          rhs = rhs_comma.strip.gsub(/,\z/, '').strip
          case
            # 'key' => 999
            when /\A(?<digits>\d+)\z/ =~ rhs
              stack[0][key] = digits.to_i

            # 'key' => 'blah'
            when /\A'(?<chars>.*)'\z/ =~ rhs
              stack[0][key] = chars

            # 'key' => {}
            when /\A\{\s*\}\z/ =~ rhs
              stack[0][key] = {}

            # 'key' => {
            when /\A\{\z/ =~ rhs
              stack.unshift({}, key)

            else
              puts "!!! key = #{key} => rhs = #{rhs.inspect}"
              raise "Cannot parse key = #{key} => rhs = #{rhs.inspect}"
          end

        else
          puts "!!! line = #{line.inspect}"
          raise "Cannot parse #{line}"
      end

      stack
    end
  end

  def ruby_struct
    @ruby_struct ||= rubified.first
  end

  def options
    unless @options
      count = ruby_struct[:options].count
      @options = (1..count).map do |index|
        ruby_struct[:options][index]
      end
    end

    @options
  end

  def flow
    @flow ||= options.select{ |option| 'flow' == option[:type] }.first[:original]
  end

  def metadata
    @metadata ||= Metadata.new(ruby_struct[:metadata])
  end

  def self.build_connection(comp)
    "#{comp[:action]} #{comp[:protocol]} #{comp[:src]} #{comp[:srcport]} -> #{comp[:dst]} #{comp[:dstport]}"
  end

  def attributes
    @attributes ||= ruby_struct.slice(:sid, :action, :protocol, :src, :srcport, :dst, :dstport).merge({
        gid:            ruby_struct[:gid] || 1,
        rev:            ruby_struct[:revision],
        class_type:     ruby_struct[:classification],
        connection:     self.class.build_connection(ruby_struct),
        message:        ruby_struct[:name],
    })
  end

  def parsed?
    @parsed ||= !(parsed_lines.match(/FAILED/))
  end

  def msg?
    !!(/msg/ =~ parsed_lines)
  end

  def msg_hash
    rule = rule_content

    rule_params = {
        sid: /sid:\s*(\d+)\s*;/.match(rule) ? /sid:\s*(\d+)\s*;/.match(rule_content)[1].to_i : nil,
        gid: /gid:\s*(\d+)\s*;/.match(rule) ? /gid:\s*(\d+)\s*;/.match(rule_content)[1].to_i : 1,
        rev: /rev\s*:\s(.+)/.match(rule_content) ? /rev\s*:\s(.+)/.match(rule_content)[1] : 1,
        connection: rule.match(/connection:\s*(.+?)\(/) ? rule.match(/connection:\s*(.+?)\(/)[1] : nil,
        message: rule.match(/msg:\w*(.+?);/) ? rule.match(/msg:\w*(.+?);/)[1].gsub(/"/, '') : nil,
        detection: rule.match(/detection:\s*(.+?);/) ? rule.match(/detection:\s*(.+?);/)[1] : nil,
        flow: rule.match(/flow:\s*(.+?);/) ? rule.match(/flow:\s*(.+?);/)[1] : nil,
        metadata: /metadata\s*:(.+?)\;/.match(rule) ? /metadata\s*:(.+?)\;/.match(rule)[1].strip : nil,
        class_type: /classtype\s*:(.*)\)/.match(rule_content) ? /classtype\s*:(.*)\)/.match(rule_content)[1] : nil,
    }.reject { |k, value,| value.nil? || value == '<MISSING>' }
  end

  def nonmsg_hash
    parsed_lines.each_line.inject({}) do |parsed_hash, line|
      if /\A\s*(?<key>\w+)\s*:\s?(?<value>.*[\S])\s*\z/ =~ line
        parsed_hash[key.downcase.to_sym] = value unless value.nil? || value == '<MISSING>'
      end
      parsed_hash
    end
  end

  def parsed_hash
    @parsed_hash ||= msg? ? msg_hash : nonmsg_hash
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
