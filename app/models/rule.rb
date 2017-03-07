require 'open3'
require 'tempfile'

class Rule < ApplicationRecord
  has_paper_trail

  has_and_belongs_to_many :bugs
  has_and_belongs_to_many :attachments
  has_and_belongs_to_many :references, dependent: :destroy
  has_one :rule_doc, dependent: :destroy

  belongs_to :rule_category, optional: true
  
  #after_create { |rule| rule.record 'create' if Rails.configuration.websockets_enabled == "true" }
  #after_update { |rule| rule.record 'update' if Rails.configuration.websockets_enabled == "true" }
  #after_destroy { |rule| rule.record 'destroy' if Rails.configuration.websockets_enabled == "true" }

  PUBLISH_STATUS_SYNCHED        = 'SYNCHED'         #unchanged from VC and up to date with VC
  PUBLISH_STATUS_NEW            = 'NEW'             #new rule unknowned to VC
  PUBLISH_STATUS_CURRENT_EDIT   = 'CURRENT_EDIT'    #draft of rule edited in UI, but optimistic it can be checked in
  PUBLISH_STATUS_STALE_EDIT     = 'STALE_EDIT'      #draft of rule, but VC rev has changed and cannot be checked in

  def record(action)
    record = { resource: 'rule',
              action: action,
              id: self.id,
              obj: self }
    PublishWebsocket.push_changes(record)
  end

  def create_references(references)
    references.each do |reference|
      self.references << Reference.create(reference.permit(:reference_type_id, :reference_data))
    end
  end

  def self.create_a_rule(content)
    begin
      raise Exception.new('No rules to add') if content.blank?
      text_rules = content.each_line.to_a.sort.uniq.map { |t| t.chomp }.compact.reject { |e| e.empty? }
      raise Exception.new('No rules to add') if text_rules.empty?
      # Loop through all of the rules
      text_rules.each do |text_rule|
        begin
          if text_rule =~ / sid:(\d+);/ # if this rule has a sid then we can attempt to create it
            @record = Rule.update_generate_rule($1)
            @record.state = 'New'
            @record.publish_status = PUBLISH_STATUS_NEW
            @record.rev = 1
            @record.save
          end
        rescue Exception => e
          raise Exception.new("{rule_error: {content: #{text_rule},error:#{e}}}")
        end
      end
    rescue Exception => e
      raise Exception.new("{rule_error: {content: 'Error creating rule.', error:#{e}}}")
    end
  end

  def self.gid_regexp(gid)
    Regexp.new("gid:\\s*#{gid}\\s*;")
  end

  def self.anygid_regexp
    @anygid_regexp ||= Regexp.new("gid:\\s*\\d+\\s*;")
  end

  def self.grep_line_from_file(sid, gid)
    rule_grep_output = `grep -Hrn "sid:\s*#{sid}\s*;" #{Rails.root}/extras/snort`
    thisgid_regexp = gid_regexp(gid)
    rule_grep_lines = rule_grep_output.split("\n").select do |grep_line|
      case
        when thisgid_regexp =~ grep_line
          true
        when anygid_regexp =~ grep_line
          false
        when 1 == gid
          true
        else
          false
      end
    end
    raise "Rule doesn't exist." if 0 == rule_grep_lines.length
    raise "Duplicate rules found for sid #{sid}." unless 1 == rule_grep_lines.length

    rule_grep_lines[0]
  end

  def self.import_rule(sid, gid = 1)
    raise 'No rule sid provided' unless sid

    found_rule = Rule.where(sid: sid).first
    return found_rule if found_rule

    filename, line_number, rule_content = grep_line_from_file(sid, gid).partition(/:\d+:/)
    # remove anything before the first alert
    # rule_content.strip!.gsub!(/(?=^).+?(?=alert)/, '')
    rule_content.strip!

    parsed = Rule.visruleparser(rule_content)
    rule_hash = Rule.parse_from_visrule(rule_content, parsed)
    rule_hash['sid'] = sid
    rule_hash['rule_parsed'] = parsed[:rule]
    rule_hash['rule_warnings'] = parsed[:errors]
    rule_hash['cvs_rule_parsed'] = parsed[:rule]
    rule_hash['cvs_rule_content'] = rule_content
    new_rule = Rule.create(rule_hash)
    new_rule.associate_references(rule_content)

    new_rule
  end

  def extract_rule
    begin
      if !content.nil?

        # Make sure we don't have multiple rules in one
        if content =~ /[\r\n]/
          raise 'Only create one rule at a time'
        end

        # First make sure we can parse it
        parsed = Rule.parse_rule(content)

        if parsed.nil?
          raise 'Failed to parse rule'
        end

        if !parsed['sid'].nil? && !sid.nil?
          raise "Mismatched sid in updated rule. Expected #{sid} not #{parsed['sid']}" if parsed['sid'] != sid
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

                if !references.empty?
                  if !references.includes?(reference)
                    references << reference
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
        raise 'Neither gid nor sid content is set'
      end
      return true
    rescue Exception => e
      errors.add(:base, e.to_s)
      e.backtrace.each do |l|
        errors.add(:base, l)
      end
      return false
    end
  end

  def rule_classification
    split = rule_content.split(';')
    classification_index = split.index{|s| s.include?("classtype")}
    impact = split[classification_index].split(':')[1].scan(/[a-z-]/).join
    RulesHelper::CLASSIFICATION[impact]
  end

  def self.parse_rule(rule)
    begin
      raise Exception.new('Rule has no content') if rule.nil?
      # Cache this output as well to speed up any changes
      message = Rails.cache.fetch("rules.content.#{Digest::MD5::hexdigest(rule)}") do
        data = {}
        # parse the rule
        split_rule = rule.scan(/(\w+:)([^\;]*)/)
        split_rule.each do |key, value|
          data[key.gsub(':', '')] = value
        end
        return data
      end
      return message
    rescue Exception => e
      raise Exception.new("{rule_parse_error: {content: #{rule},error:#{e}}}")
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
    references.each { |r| current_references << ReferenceType.where(id: r.reference_type_id).first.name + ',' + r.reference_data }
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

  def self.hash_visrule(ruleline)
    ruleline.split("\n").inject({}) do |attrs, line|
      if /^\s*(?<key>\w*)\s*:(?<value>.*)$/ =~ line
        value = value[1..-1] if ' ' == value[0]
        attrs[key.downcase.to_sym] = value
      end

      attrs
    end
  end

  def self.gid_from_visrule(rule_content, parsed_attrs)
    return parsed_attrs[:gid] if parsed_attrs[:gid]

    gid_match = nil
    /gid:\s*(?<gid_match>\d+)\s*;/ =~ rule_content

    gid_match ? gid_match.to_i : 1
  end

  # Takes the hash and adds some data from the rules text
  # @param [String, #read] rule the line of rule text.
  # @param [Hash, #read] parsed A hash, which must have :rule set by visruleparser.
  # @return [Hash] the original hash, now with additional data.
  def self.parse_from_visrule(rule, parsed)
    if parsed[:rule].match(/FAILED/)
      rule_params = {
          message: rule.match(/msg:\w*(.+?);/) ? rule.match(/msg:\w*(.+?);/)[1].gsub(/"/, '') : nil,
          rule_content: rule,
          rule_parsed: parsed[:rule],
          rule_failures: parsed[:rule],
          committed: false,
          state: 'FAILED',
      }.reject { |k, v,| v.nil? || v == '<MISSING>' }

    elsif parsed[:rule].match(/msg/)
      parsed_attrs = hash_visrule(parsed[:rule])
      rule_sid = /sid:\s*(\d+)\s*;/.match(rule) ? /sid:\s*(\d+)\s*;/.match(rule)[1].to_i : nil
      message = rule.match(/msg:\w*(.+?);/) ? rule.match(/msg:\w*(.+?);/)[1].gsub(/"/, '') : '<MISSING>'

      rule_params = {

          sid: rule_sid,
          rule_content: rule,
          rule_parsed: parsed[:rule],
          gid: gid_from_visrule(rule, parsed_attrs),
          rev: /Rev\s*:\s(.+)/.match(parsed[:rule]) ? /Rev\s*:\s(.+)/.match(parsed[:rule])[1] : 1,
          connection: rule.match(/connection:\s*(.+?)\(/) ? rule.match(/connection:\s*(.+?)\(/)[1] : '<MISSING>',
          message: message,
          detection: rule.match(/detection:\s*(.+?);/) ? rule.match(/detection:\s*(.+?);/)[1] : '<MISSING>',
          flow: rule.match(/flow:\s*(.+?);/) ? rule.match(/flow:\s*(.+?);/)[1] : '<MISSING>',
          metadata: /metadata\s*:(.+?)\;/.match(rule) ? /metadata\s*:(.+?)\;/.match(rule)[1].strip : '<MISSING>',
          class_type: /classtype\s*:(.*)\)/.match(parsed[:rule]) ? /classtype\s*:(.*)\)/.match(parsed[:rule])[1] : '<MISSING>',
          committed: true,
          state: rule_sid ? 'UNCHANGED' : 'NEW',
      }
      rule_params.reject { |k, v,| v.nil? || v == '<MISSING>' }
      rule_params[:rule_failures] = nil


    else
      parsed_attrs = hash_visrule(parsed[:rule])
      rule_sid = /sid:\s*(\d+)\s*;/.match(rule) ? /sid:\s*(\d+)\s*;/.match(rule)[1].to_i : nil
      detection = /Detection\s*:\n(.*)Metadata/m.match(parsed[:rule]) ? /Detection\s*:\n(.*)Metadata/m.match(parsed[:rule])[1].gsub(/\t|#\n/, '').strip : nil
      message = /Message\s*:\s(.*)/.match(parsed[:rule]) ? /Message\s*:\s(.*)/.match(parsed[:rule])[1] : '<MISSING>'
      rule_category = RuleCategory.find_or_create_by(category: message.split(' ')[0])

      rule_params = {

          sid: rule_sid,
          rule_content: rule,
          rule_parsed: parsed[:rule],
          gid: gid_from_visrule(rule, parsed_attrs),
          rev: /Rev\s*:\s(.+)/.match(parsed[:rule]) ? /Rev\s*:\s(.+)/.match(parsed[:rule])[1] : 1,
          connection: /Connection\s*:\s(.+)/.match(parsed[:rule]) ? /Connection\s*:\s(.+)/.match(parsed[:rule])[1] : '<MISSING>',
          message: message,
          detection: detection.nil? ? "<MISSING>" : detection[-1, 1] == ';' ? detection : detection + ';',
          flow: /Flow\s*:\s(.+)/.match(parsed[:rule]) ? /Flow\s*:\s(.+)/.match(parsed[:rule])[1] : '<MISSING>',
          metadata: /metadata\s*:(.+?)\;/.match(rule) ? /metadata\s*:(.+?)\;/.match(rule)[1].strip : '<MISSING>',
          class_type: /Classtype\s*:\s(.*)/.match(parsed[:rule]) ? /Classtype\s*:\s(.*)/.match(parsed[:rule])[1] : '<MISSING>',
          committed: true,
          state: rule_sid ? 'UNCHANGED' : 'NEW',
          rule_category_id: rule_category.id
      }
      rule_params.reject { |k, v,| v.nil? || v == '<MISSING>' }
      rule_params[:rule_failures] = nil
    end

    rule_params
  end

  # Runs the visruleparser perl script to parse a line of rule text.
  # @param [String, #read] rule_text the line of rule text
  # @return [Hash] hash with :rule and :errors text populated.
  def self.visruleparser(rule_text)
    return nil if rule_text.empty?
    parsed = {}
    temp_rule = Tempfile.new('temp.rules')
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

  # Takes the hash and adds some data from the rules text
  # @param [String, #read] rule the line of rule text.
  # @return [Hash] a hash, with data from parsing rule text.
  def self.parse_and_create_rule(rule)
    parsed = visruleparser(rule)
    parse_from_visrule(rule, parsed)
  end

  # Takes a rule and populates all the attributes to create a Rule record object.
  # @param [String, #read] rule_content the line of rule text.
  # @return [Hash] a hash, with all the attributes to create a Rule record object
  def self.full_parse(rule_content)
    raise "Rule text missing." if rule_content.nil?

    rule_content.strip!

    parsed = visruleparser(rule_content)
    rule_attrs = parse_from_visrule(rule_content, parsed)
    rule_attrs['rule_parsed'] = parsed[:rule]
    rule_attrs['rule_warnings'] = parsed[:errors]
    rule_attrs['cvs_rule_parsed'] = parsed[:rule]
    rule_attrs['cvs_rule_content'] = rule_content
    rule_attrs
  end

  # Take a line from a rule file and saves to database unless rev is unchanged
  # @param [String, #read] rule_content the line of text from a rule file.
  # @param [String, #read] filename the path or name of the file.
  # @param [Fixnum, #read] linenumber the line number from the input rules file.
  # @return [Rule] the rule loaded or nil if failed
  # @raise [RuntimeError] could not process
  def self.load_rule_from_content(rule_content, filename = '', linenumber = nil)
    rule_attrs = full_parse(rule_content)
    return nil unless rule_attrs
    return nil if 'FAILED' == rule_attrs[:state]
    raise 'No rule gid provided' unless rule_attrs[:gid]
    raise 'No rule sid provided' unless rule_attrs[:sid]

    rule_attrs[:filename] = filename
    rule_attrs[:linenumber] = linenumber

    rule = where(gid: rule_attrs[:gid]).where(sid: rule_attrs[:sid]).first
    case
      when rule.nil?
        rule_attrs[:publish_status] = PUBLISH_STATUS_NEW
        rule = create!(rule_attrs)
        rule.associate_references(rule_content)
      when rule.draft?
        rule.update(publish_status: PUBLISH_STATUS_STALE_EDIT)
      when rule.rev != rule_attrs[:rev].to_i
        rule_attrs[:publish_status] = PUBLISH_STATUS_SYNCHED
        rule.update(rule_attrs)
    end

    rule
  end

  # Take a line from grep output of a rule file and saves to database unless rev is unchanged
  # @param [String, #read] rule_grep_line the line of text from a rule file.
  # @return [Rule] the rule loaded, nil if failed, empty string if input was blank
  # @raise [RuntimeError] could not process
  def self.load_rule_from_grep(rule_grep_line)
    filename, line_number, rule_content = rule_grep_line. partition(/:\d+:/)

    rule_content.strip!
    if rule_content.empty?
      ''
    else
      load_rule_from_content(rule_content, filename, line_number[1..-2].to_i)
    end
  end

  def update_rule
    begin
      rule = Rule.find_rule(Rule.find(params[:id]).sid) # This will update if found
      rule.rule_state = RuleState.Unchanged
      rule.attachments.clear
      rule.save(validate: false)

    rescue Exception => e
      log_error(e)
    rescue RuleError => e
      add_error("#{rule.sid}: #{e}")
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
    rule.destroy if rule.bugs.empty? && rule.attachments.empty?
  end

  def self.create_or_update_rule(body)
    begin
      parsed = Rule.parse_rule(body)
      rule = Rule.where('sid = ?', parsed['sid']).first
      if rule.empty?
        rule = Rule.create(content: body)
        rule.gid = 1
        rule.message = parsed['msg'].gsub("\"", "")
        rule.sid = parsed['sid']
        rule.rev = parsed['revision']
        rule.state = 'Unchanged'
      else
        rule.content = body
        rule.message = parsed['msg'].gsub("\"", "")
        rule.gid = 1
        rule.sid = parsed['sid']
        rule.rev = parsed['revision']
        rule.state = 'Unchanged'
      end
      rule.publish_status = PUBLISH_STATUS_SYNCHED
      rule.save
      return rule
    rescue Exception => e
      raise Exception.new(e)
    end
  end

  def self.find_current_rule(sid)
    Dir.entries(Rails.configuration.snort_rule_path).each do |f|
      # Don't include .stub.rules hidden rule files
      if f =~ /^[^\.]/ && f =~ /\.rules$/
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
    ApplicationRecord.transaction do
      rules.each do |rule|
        rule.save
      end
    end
  end

  def sort_rules_by_state
    case (state)
    when 'FAILED'
      val = 0
    when 'NEW'
      val = 1
    when 'UPDATED'
      val = 2
    when 'UNCHANGED'
      val = 3
    else
      val = 3
    end
    val
  end

  # Tests if rule is the current version in VC
  # @return [boolean] true iff rule is latest version synced with VC
  def synched?
    %w[UNCHANGED].include?(state)
  end

  # Tests if rule is a user edited version
  # @return [boolean] true iff rule is a user edited version
  def draft?
    %w[NEW UPDATED FAILED].include?(state)
  end

  # Tests if edited rule is new
  # @return [boolean] true iff rule is a new edited rule
  def new_rule?
    draft? && sid.nil?
  end

  # Tests if edited rule is an edited update to an existing rule
  # @return [boolean] true iff rule is a updated edited rule
  def edited_rule?
    draft? && sid.present?
  end

  # Tests if edited rule is in progress while VC updated the rule externally
  # @return [boolean] true iff rule is a updated edited rule but VC has not changed
  def current_edit?
    edited_rule? && (PUBLISH_STATUS_CURRENT_EDIT == publish_status)
  end

  # Tests if edited rule is in progress while VC updated the rule externally
  # @return [boolean] true iff rule is a updated edited rule and VC has updated the rule
  def stale_edit?
    edited_rule? && (PUBLISH_STATUS_STALE_EDIT == publish_status)
  end
end
