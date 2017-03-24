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
    parsed_hash[:sid].to_i
  end
end
