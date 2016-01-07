require 'open3'
require 'tempfile'

class Rule < ActiveRecord::Base
  has_and_belongs_to_many :bugs
  has_and_belongs_to_many :attachments
  has_and_belongs_to_many :references, dependent: :destroy

  after_create { |rule| rule.record 'create' if Rails.configuration.websockets_enabled == "true" }
  after_update { |rule| rule.record 'update' if Rails.configuration.websockets_enabled == "true" }
  after_destroy { |rule| rule.record 'destroy' if Rails.configuration.websockets_enabled == "true" }

  def record action
    record = {resource: 'rule',
              action: action,
              id: self.id,
              obj: self}
    PublishWebsocket.push_changes(record)
  end

  def self.create_a_rule(content)
    begin
      raise Exception.new('No rules to add') if content.blank?
      text_rules = content.each_line.to_a.sort.uniq.map { |t| t.chomp }.compact.reject { |e| e.empty? }
      raise Exception.new('No rules to add') if text_rules.empty?
      # Loop through all of the rules
      text_rules.each do |text_rule|
        begin
          if text_rule =~ / sid:(\d+);/ #if this rule has a sid then we can attempt to create it
            @record = Rule.update_generate_rule($1)
            @record.state = "New"
            @record.rev = 1
            @record.save
          end
        rescue Exception => e
          raise Exception.new("{rule_error: {content: #{text_rule},error:#{e.to_s}}}")
        end
      end
    rescue Exception => e
      raise Exception.new("{rule_error: {content: 'Error creating rule.', error:#{e.to_s}}}")
    end
  end

  def self.import_rule(sid)
    if sid
      found_rule = Rule.where(id: sid).first
      if found_rule.nil?
        rule_text = `grep -Hrn "sid:#{sid}" #{Rails.root}/extras/snort`.split(/:\d[\d]*:/)[1]
        if rule_text.nil?
          raise "Rule doesn't exist."
        else
          # remove anything before the first alert
          # rule_text.strip!.gsub!(/(?=^).+?(?=alert)/, '')
          rule_text.strip!
          parsed = Rule.visruleparser(rule_text)
          new_rule = Rule.create(Rule.parse_and_create_rule(rule_text))
          new_rule.update(
              rule_parsed: parsed[:rule],
              rule_warnings: parsed[:errors],
              cvs_rule_parsed: parsed[:rule],
              cvs_rule_content: rule_text
          )
          new_rule.associate_references(rule_text)
          return new_rule
        end
      else
        return found_rule
      end
    else
      raise "No rule sid provided"
    end
  end

  def extract_rule
    begin
      if not self.content.nil?

        # Make sure we don't have multiple rules in one
        if self.content =~ /[\r\n]/
          raise "Only create one rule at a time"
        end

        # First make sure we can parse it
        parsed = Rule.parse_rule(self.content)


        if parsed.nil?
          raise "Failed to parse rule"
        end

        if not parsed['sid'].nil? and not self.sid.nil?
          raise "Mismatched sid in updated rule. Expected #{self.sid} not #{parsed['sid']}" if parsed['sid'] != self.sid
        end

        self.message = parsed['name']
        self.gid = 1
        self.sid = parsed['sid']
        self.rev = parsed['revision']
        self.content = parsed['optomized']

        unless parsed['references'].nil?
          parsed['references'].each do |type, ref|
            begin
              reference_type = ReferenceType.find_by_name(type)

              unless reference_type.nil?
                reference = Reference.find_or_create_by_reference_type_id_and_data(reference_type.id, ref.keys.first)

                if not self.references.empty?
                  if not self.references.includes?(reference)
                    self.references << reference
                  end
                end
              end
            rescue ActiveRecord::RecordNotUnique => e
              # Ignore
            rescue Exception => e
              raise
            end
          end
        end
      elsif gid.nil?
        raise "Neither gid nor sid content is set"
      end
      return true
    rescue Exception => e
      self.errors.add(:base, e.to_s)
      e.backtrace.each do |l|
        self.errors.add(:base, l)
      end
      return false
    end
  end

  def self.parse_rule(rule)
    begin
      raise Exception.new("Rule has no content") if rule.nil?
      # Cache this output as well to speed up any changes
      message = Rails.cache.fetch("rules.content.#{Digest::MD5::hexdigest(rule)}") do
        data ={}
        # parse the rule
        split_rule = rule.scan(/(\w+:)([^\;]*)/)
        split_rule.each do |key, value|
          data[key.gsub(":", "")] = value
        end
        return data
      end
      return message
    rescue Exception => e
      raise Exception.new("{rule_parse_error: {content: #{rule},error:#{e.to_s}}}")
    end
  end

  def associate_references(rule_text)
    references = []
    rule_text.split(';').each { |r| references << r.strip.gsub!('reference:', '') if r.match(/reference\W*:/) }
    references.each do |r|
      r = r.split(',')
      unless r[1].empty?
        new_reference = Reference.create(reference_type: ReferenceType.where(name: r[0]).first, reference_data: r[1])
        self.references << new_reference
      end
    end
  end

  def update_references(rule_text)
    current_references = []
    self.references.each { |r| current_references << ReferenceType.where(id: r.reference_type_id).first.name + ',' + r.reference_data }
    references = []
    rule_text.split(';').each { |r| references << r.strip.gsub!('reference:', '') if r.match(/reference\W*:/) }
    references.each do |r|
      # skip this reference if it already exists
      if current_references.include? r
        current_references.delete(r)
        # otherwise create it
      else
        ref_type = r.split(',')[0]
        ref_data = r.split(',')[1]
        self.references << Reference.create(reference_type: ReferenceType.where(name: ref_type).first, reference_data: ref_data) unless ref_data.strip.empty?
      end
    end
    # delete the reference if it is no longer part of the record
    current_references.each do |r|
      ref_type = r.split(',')[0]
      ref_data = r.split(',')[1]
      self.references.where(reference_type: ReferenceType.where(name: ref_type).first, reference_data: ref_data).each { |ref| ref.destroy! }
    end
  end

  def self.parse_and_create_rule(rule)
    parsed = Rule.visruleparser(rule)

    if parsed[:rule].match(/FAILED/)
      rule_params = {
          :message => rule.match(/msg:\w*(.+?);/) ? rule.match(/msg:\w*(.+?);/)[1].gsub(/"/, '') : nil,
          :rule_content => rule,
          :rule_parsed => parsed[:rule],
          :rule_failures => parsed[:rule],
          :committed => false,
          :state => 'FAILED'
      }.reject() { |k, v,| v.nil? || v == "<MISSING>" }
    else
      rule_sid = /sid:\s*(\d+)\s*;/.match(rule) ? /sid:\s*(\d+)\s*;/.match(rule)[1].to_i : nil
      detection = /Detection\s*:\n(.*)Metadata/m.match(parsed[:rule]) ? /Detection\s*:\n(.*)Metadata/m.match(parsed[:rule])[1].gsub(/\t|#\n/, '').strip : nil
      message = /Message\s*:\s(.*)/.match(parsed[:rule]) ? /Message\s*:\s(.*)/.match(parsed[:rule])[1] : "<MISSING>"
      rule_params = {
          :id => rule_sid,
          :sid => rule_sid,
          :rule_content => rule,
          :rule_parsed => parsed[:rule],
          :gid => rule_sid ? 1 : nil,
          :rev => /Rev\s*:\s(.+)/.match(parsed[:rule]) ? /Rev\s*:\s(.+)/.match(parsed[:rule])[1] : 1,
          :connection => /Connection\s*:\s(.+)/.match(parsed[:rule]) ? /Connection\s*:\s(.+)/.match(parsed[:rule])[1] : "<MISSING>",
          :message => message,
          :detection => detection.nil? ? "<MISSING>" : detection[-1, 1] == ';' ? detection : detection + ';',
          :flow => /Flow\s*:\s(.+)/.match(parsed[:rule]) ? /Flow\s*:\s(.+)/.match(parsed[:rule])[1] : "<MISSING>",
          :metadata => /metadata\s*:(.+?)\;/.match(rule) ? /metadata\s*:(.+?)\;/.match(rule)[1].strip : "<MISSING>",
          :class_type => /Classtype\s*:\s(.*)/.match(parsed[:rule]) ? /Classtype\s*:\s(.*)/.match(parsed[:rule])[1] : "<MISSING>",
          :committed => true,
          :state => rule_sid ? 'UNCHANGED' : 'NEW'
      }
      rule_params.reject() { |k, v,| v.nil? || v == "<MISSING>" }
      rule_params[:rule_failures] = nil
    end
    rule_params
  end

  def self.visruleparser(rule_text)
    return nil if rule_text.nil?
    parsed = Hash.new
    temp_rule = Tempfile.new("temp.rules")
    temp_rule.write(rule_text.gsub(/\#\s/, ''))
    temp_rule.rewind
    Open3.popen3("#{Rails.configuration.visruleparser_path} #{temp_rule.path}") do |stdin, stdout, stderr, wait_thru|
      text = stdout.read
      unless text.empty?
        parsed[:rule] = text.split(/%{80}|\*{80}/)[1].strip
        parsed[:errors] = text.split(/%{80}|\*{80}/)[2] ? text.split(/%{80}|\*{80}/)[2].gsub('%', '').strip : ''
        parsed[:errors] += stderr.read
      end
    end
    temp_rule.close
    parsed
  end

  def update_rule
    begin
      rule = Rule.find_rule(Rule.find(params[:id]).sid) # This will update if found
      rule.rule_state = RuleState.Unchanged
      rule.attachments.clear
      rule.save(:validate => false)

    rescue Exception => e
      log_error(e)
    rescue RuleError => e
      add_error("#{rule.sid}: #{e.to_s}")
    end

    redirect_to request.referer
  end

  def remove_rule
    begin
      remove_rule_from_bug(Bug.find(active_scaffold_session_storage[:constraints][:bugs]), Rule.find(params[:id]))
    rescue Exception => e
      log_error(e)
    end

    redirect_to request.referer
  end

  def remove_rule_from_bug(bug, rule)
    # Remove any new alerts from the attachments
    if rule.rule_state == RuleState.New
      bug.attachments.each do |attachment|
        attachment.rules.delete(rule)
      end
    end

    # Remove the rule reference
    bug.rules.delete(rule)

    # Remove this rule if it is no longer needed
    rule.destroy if rule.bugs.empty? and rule.attachments.empty?
  end

  def self.create_or_update_rule(body)
    begin
      parsed = Rule.parse_rule(body)
      rule = Rule.where("sid = ?", parsed['sid']).first
      if rule.empty?
        rule = Rule.create(:content => body)
        rule.gid = 1
        rule.message = parsed['msg'].gsub("\"", "")
        rule.sid = parsed['sid']
        rule.rev = parsed['revision']
        rule.state = "Unchanged"
      else
        rule.content = body
        rule.message = parsed['msg'].gsub("\"", "")
        rule.gid = 1
        rule.sid = parsed['sid']
        rule.rev = parsed['revision']
        rule.state = "Unchanged"
      end
      rule.save
      return rule
    rescue Exception => e
      raise Exception.new(e)
    end
  end

  def self.find_current_rule(sid)
    Dir.entries(Rails.configuration.snort_rule_path).each do |f|

      # Don't include .stub.rules hidden rule files
      if f =~ /^[^\.]/ and f =~ /\.rules$/
        File.read("#{Rails.configuration.snort_rule_path}/#{f}").each_line do |line|
          line = line.chomp.gsub(/^# /, '')

          if line =~ /sid:#{sid};/
            return line
          end
        end
      end
    end

    raise RuleError.new("Unable to find sid #{sid}")
  end

  def self.update_generate_rule(sid)
    begin
      return Rule.create_or_update_rule(Rule.find_current_rule(sid))
    rescue Exception => e
      raise Exception.new(e)
    end
  end

  def self.update_rules(rules)
    ActiveRecord::Base.transaction do
      rules.each do |rule|
        rule.save
      end
    end
  end

end