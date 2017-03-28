class VisruleParser
  attr_reader :rule_content

  def initialize(rule_content)
    @rule_content = rule_content
  end

  def parse
    return nil if @rule_content.empty?
    temp_rule = Tempfile.new('temp.rules')
    temp_rule.write(@rule_content.gsub(/\#\s/, ''))
    temp_rule.rewind
    Open3.popen3("#{Rails.configuration.visruleparser_path} #{temp_rule.path}") do |stdin, stdout, stderr, wait_thru|
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

  def parsed_lines
    unless @parsed_lines
      parse
    end
    @parsed_lines
  end

  def errors
    unless @errors
      parse
    end
    @errors
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
        rev: /[Rr]ev\s*:\s(.+)/.match(rule_content) ? /[Rr]ev\s*:\s(.+)/.match(rule_content)[1] : 1,
        connection: rule.match(/connection:\s*(.+?)\(/) ? rule.match(/connection:\s*(.+?)\(/)[1] : nil,
        message: rule.match(/msg:\w*(.+?);/) ? rule.match(/msg:\w*(.+?);/)[1].gsub(/"/, '') : nil,
        detection: rule.match(/detection:\s*(.+?);/) ? rule.match(/detection:\s*(.+?);/)[1] : nil,
        flow: rule.match(/flow:\s*(.+?);/) ? rule.match(/flow:\s*(.+?);/)[1] : nil,
        metadata: /metadata\s*:(.+?)\;/.match(rule) ? /metadata\s*:(.+?)\;/.match(rule)[1].strip : nil,
        class_type: /classtype\s*:(.*)\)/.match(rule_content) ? /classtype\s*:(.*)\)/.match(rule_content)[1] : nil,
    }.reject { |k, v,| v.nil? }
  end

  def nonmsg_hash
    parsed_lines.each_line.inject({}) do |parsed_hash, line|
      if /\A\s*(?<key>\w+)\s*:\s?(?<value>.*[\S])\s*\z/ =~ line
        parsed_hash[key.downcase.to_sym] = value
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
