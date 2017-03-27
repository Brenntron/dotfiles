require 'open3'
require 'tempfile'

# Records for rules both synched with CVS and drafts of rules from the UI.
#
# When a rule has not been edited by our users, it will be updated with changed from CVS.
# When a user saves a draft of an edit to a rule, that draft is stored instead and CVS synching is suppressed.
# A new rule originating in our UI will be saved here, but obvious will have no synching until committed to CVS.
#
# Database Fields:
# state (String) the display text for the state of the rule (see below)
# edit_status [String] if the rule is new, an update, or a rule synched with version control (see below)
# publish_status (String) status in saving an edit to version control (see below)
# parsed (Boolean) if the rule content succeeded parsing (see below)
# on (Boolean) if the rule is uncommented in the rule file
# filename [String] the (relative or absolute) filename where the rule came from or is stored
# linenumber [Integer] the line in the rule file where the rule was read from
#
#                           |sid|  state  |edit_status|publish_status|parsed|
# All Rules
# * synched with CVS
#   * valid                 |int|UNCHANGED|  SYNCHED  |    SYNCHED   | true | valid rule up to date with CVS
#   * failed visruleparse   .............................. rules which fail visruleparse are not loaded
# * draft
#   * new
#     * valid               |nil|   NEW   |    NEW    | CURRENT_EDIT | true | new rule created from UI or web services
#     * failed parse        |nil|  FAILED |    NEW    | CURRENT_EDIT |false | new rule which failed visruleparse
#   * edit
#     * current edit
#       * valid             |int| UPDATED |   EDIT    | CURRENT_EDIT | true | CVS rule edited in UI or web service
#       * failed parse      |int|  FAILED |   EDIT    | CURRENT_EDIT |false | edited rule which failed visruleparse
#     * out of date
#       * valid             |int| UPDATED |   EDIT    |  STALE_EDIT  | true | edited rule, but CVS has since been updated and cannot save
#       * failed parse      |int|  FAILED |   EDIT    |  STALE_EDIT  |false | stale edit which failed visruleparse
#
class Rule < ApplicationRecord
  has_paper_trail

  has_and_belongs_to_many :bugs
  has_and_belongs_to_many :references, dependent: :destroy
  has_one :rule_doc, dependent: :destroy

  belongs_to :rule_category, optional: true
  
  #after_create { |rule| rule.record 'create' if Rails.configuration.websockets_enabled == "true" }
  #after_update { |rule| rule.record 'update' if Rails.configuration.websockets_enabled == "true" }
  #after_destroy { |rule| rule.record 'destroy' if Rails.configuration.websockets_enabled == "true" }

  EDIT_STATUS_SYNCHED           = 'SYNCHED'         #unchanged from VC and up to date with VC
  EDIT_STATUS_NEW               = 'NEW'             #new rule unknowned to VC
  EDIT_STATUS_EDIT              = 'EDIT'            #draft of rule edited in UI

  PUBLISH_STATUS_SYNCHED        = 'SYNCHED'         #unchanged from VC and up to date with VC
  PUBLISH_STATUS_CURRENT_EDIT   = 'CURRENT_EDIT'    #draft of rule edited in UI, but optimistic it can be checked in
  PUBLISH_STATUS_STALE_EDIT     = 'STALE_EDIT'      #draft but VC rev has changed and cannot be checked in
  PUBLISH_STATUS_PUBLISHING     = 'PUBLISHING'      #draft in process of being written to VC

  scope :by_sid, ->(sid, gid = 1) { where(sid: sid).where(gid: gid) }

  def record(action)
    record = { resource: 'rule',
              action: action,
              id: self.id,
              obj: self }
    PublishWebsocket.push_changes(record)
  end

  def create_references(references)
    references.each do |reference|
      ref = Reference.find_or_create_by(reference_data: reference.permit(:reference_type_id, :reference_data))
      self.references << ref unless self.references.include?(ref)
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
            @record.edit_status = EDIT_STATUS_NEW
            @record.publish_status = PUBLISH_STATUS_CURRENT_EDIT
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

  def self.grep_line_from_file(sid, gid, filepath = nil)
    filepath ||= "#{Rails.root}/extras/snort"
    rule_grep_output = `grep -Hrn "sid:\\s*#{sid}\\s*;" #{filepath}`
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

  def self.hash_from_rule_content(rule_content, sid)
    # remove anything before the first alert
    # rule_content.strip!.gsub!(/(?=^).+?(?=alert)/, '')
    rule_content.strip!

    parsed = Rule.visruleparser(rule_content)
    rule_attrs = Rule.parse_from_visrule(rule_content, parsed)
    rule_attrs['sid'] = sid
    rule_attrs['rule_parsed'] = parsed[:rule]
    rule_attrs['rule_warnings'] = parsed[:errors]
    rule_attrs['cvs_rule_parsed'] = parsed[:rule]
    rule_attrs['cvs_rule_content'] = rule_content

    rule_attrs
  end

  def import
    grep_filename, line_number, rule_content = Rule.grep_line_from_file(sid, gid, filename).partition(/:\d+:/)

    rule_attrs = Rule.hash_from_rule_content(rule_content, self.sid)
    rule_attrs[:state] = 'UNCHANGED'
    rule_attrs[:edit_status] = EDIT_STATUS_SYNCHED
    rule_attrs[:publish_status] = PUBLISH_STATUS_SYNCHED
    update!(rule_attrs)

    self
  end

  def self.import_rule(sid, gid = 1)
    raise 'No rule sid provided' unless sid

    found_rule = Rule.where(gid: gid).where(sid: sid).first
    return found_rule if found_rule

    filename, line_number, rule_content = grep_line_from_file(sid, gid).partition(/:\d+:/)
    new_rule = Rule.create(hash_from_rule_content(rule_content, sid))
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
        ref_type = ReferenceType.find_or_create_by(name: r[0].strip)
        new_reference = Reference.find_or_create_by(reference_type: ref_type, reference_data: r[1].strip)
        self.references << new_reference unless self.references.include?(new_reference)
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
        unless ref_data.strip.empty?
          new_reference = Reference.find_or_create_by(reference_type: ReferenceType.where(name: ref_type).first, reference_data: ref_data)
          self.references << new_reference unless self.references.include?(new_reference)
        end
      end
    end
    # delete the reference if it is no longer part of the record
    current_references.each do |r|
      ref_type = r.split(',')[0]
      ref_data = r.split(',')[1]
      ref = Reference.where(reference_type: ReferenceType.where(name: ref_type).first, reference_data: ref_data)
      self.references.destroy(ref)
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
          parsed: false,
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
          edit_status: rule_sid ? EDIT_STATUS_SYNCHED : EDIT_STATUS_NEW,
          publish_status: rule_sid ? PUBLISH_STATUS_SYNCHED : PUBLISH_STATUS_CURRENT_EDIT,
          parsed: true,
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
          edit_status: rule_sid ? EDIT_STATUS_SYNCHED : EDIT_STATUS_NEW,
          publish_status: rule_sid ? PUBLISH_STATUS_SYNCHED : PUBLISH_STATUS_CURRENT_EDIT,
          rule_category_id: rule_category.id,
          parsed: true,
      }
      rule_params.reject { |k, v,| v.nil? || v == '<MISSING>' }
      rule_params[:rule_failures] = nil
    end

    rule_params
  end

  # Runs the visruleparser perl script to parse a line of rule text.
  # @param [String, #read] rule_text the line of rule text
  # @return [Hash] hash with :rule and :errors text populated.
  def self.visruleparser(rule_content)
    parser = VisruleParser.new(rule_content)
    { rule: parser.parsed_lines, errors: parser.errors }
  end

  # Takes the hash and adds some data from the rules text
  # @param [String, #read] rule the line of rule text.
  # @return [Hash] a hash, with data from parsing rule text.
  def self.parse_and_create_rule(rule)
    parsed = visruleparser(rule)
    parse_from_visrule(rule, parsed)
  end

  # Extracts components from VisruleParser and sets field of rule.
  # Does not save the rule.
  # Does not set state, edit_status, or publish_status,
  # because these depend on where the rule and rule_content originated.
  # @param [VisruleParser, #read] parser initialized to rule content.
  def assign_from_visrule(parser)
    rule_content = parser.rule_content
    self.rule_content                   = rule_content
    self.rule_parsed                    = parser.parsed_lines
    self.rule_warnings                  = parser.errors
    self.cvs_rule_parsed                = parser.parsed_lines
    self.cvs_rule_content               = rule_content

    self.on                             = /^\s*#/ !~ rule_content
    self.parsed                         = !(parser.parsed_lines.match(/FAILED/))
    self.committed                      = !(self.parsed)


    if self.parsed?
      parsed_values = parser.parsed_hash
      self.rev                          = parsed_values[:rev]
      self.message                      = parsed_values[:message]
      self.connection                   = parsed_values[:connection]
      self.flow                         = parsed_values[:flow]
      self.class_type                   = parsed_values[:classtype]

      self.metadata = /metadata\s*:(?<meta>.+?)\;/ =~ rule_content ? meta.strip : '<MISSING>'
      self.rule_failures = nil

      # if msg (old?) format
      if parser.parsed_lines.match(/msg/)
        self.detection = /detection:\s*(?<det>.+?);/ =~ rule_content ? det : nil
      else
        detection = /Detection\s*:\n(?<det>.*)Metadata/m =~ parser.parsed_lines ? det.gsub(/\t|#\n/, '').strip : nil
        self.detection =
            if detection.nil?
              nil
            else
              detection[-1, 1] == ';' ? detection : detection + ';'
            end
        self.rule_category = RuleCategory.find_or_create_by(category: self.message.split(' ')[0])
      end
    else
      self.message                      = /msg:\w*(?<msg>.+?);/ =~ rule_content ? msg.gsub(/"/, '') : nil
      self.rule_failures                = parser.parsed_lines
    end


    self
  end

  # Gets rule with fields set from contents of rule content.
  #
  # Parses rule content.  Finds or creates rule for the given sid and gid.
  # Set the rule fields to components from parsing rule content.
  # Does not save the rule.
  # @param [String, #read] rule_content the rule content
  def self.find_and_assign_rule_content(rule_content, rule_id = nil)
    parser = VisruleParser.new(rule_content)

    rule = parser.sid && Rule.by_sid(parser.sid, parser.gid).first
    rule ||= rule_id && Rule.where(id: rule_id).first
    rule ||= Rule.new(sid: parser.sid, gid: parser.gid)
    rule.assign_from_visrule(parser)

    rule
  end

  # Take a line from a user edit and saves to database
  # @param [String, #read] rule_content the rule content
  def self.save_rule_content(rule_content, rule_id = nil)
    find_and_assign_rule_content(rule_content, rule_id).tap do |rule|
      if rule.sid
        rule.state                        = 'UPDATED'
        rule.edit_status                  = EDIT_STATUS_EDIT
      else
        rule.state                        = 'NEW'
        rule.edit_status                  = EDIT_STATUS_NEW
      end
      rule.state                          = 'FAILED' unless rule.parsed?
      rule.publish_status                 = PUBLISH_STATUS_CURRENT_EDIT unless rule.stale_edit?

      rule.save
    end
  end

  # Take a line from a rule file and saves to database if rule is unedited
  # Assumes rule content comes from synching VC.
  # @param [String, #read] rule_content the line of text from a rule file.
  # @return [Rule] the rule loaded or nil if failed
  # @raise [RuntimeError] could not process
  def self.synch_rule_content(rule_content)
    rule = find_and_assign_rule_content(rule_content)
    return nil unless rule.sid          # rule in file is a new rule with sid unassigned

    rule_db = by_sid(rule.sid, rule.gid).first

    case
      # do not load when rule file does not parse
      when !rule.parsed?
        nil
      # new rule happens when loading from file for the first time.
      when rule_db.nil?
        rule.edit_status                = EDIT_STATUS_SYNCHED
        rule.publish_status             = PUBLISH_STATUS_SYNCHED
        rule.save!
        rule.associate_references(rule_content)
        rule
      when rule_db.draft?
        rule_db.update(publish_status: PUBLISH_STATUS_STALE_EDIT)
        nil
      when rule_db.rev != rule.rev
        rule.edit_status                = EDIT_STATUS_SYNCHED
        rule.publish_status             = PUBLISH_STATUS_SYNCHED
        rule.save!
        rule
      else
        nil
    end
  end

  # Take a line from grep output of a rule file and saves to database unless rev is unchanged
  # @param [String, #read] rule_grep_line the line of text from a rule file.
  # @return [Rule] the rule loaded, nil if failed, empty string if input was blank
  # @raise [RuntimeError] could not process
  def self.load_grep(rule_grep_line)
    filename, line_number, rule_content = rule_grep_line. partition(/:\d+:/)

    rule_content.strip!
    if rule_content.empty?
      ''
    else
      rule = synch_rule_content(rule_content)
      rule.update!(filename: filename, linenumber: line_number[1..-2].to_i) if rule
    end
  end

  # Replace rule in given file with rule_content.
  # Scans file for rule with same gid and sid and replaces that line with rule_content.
  # Appends rule_content to end of file if gid and sid are not found
  # @param [String, #read] path to the file.
  def patch(filename)
    tmp = Tempfile.new(['tmprule', '.rules'])
    File.open(filename, 'rt') do |input_stream|
      IO.copy_stream(input_stream, tmp)
    end

    sid_regex = Regexp.new("sid:\\s*#{self.sid}\\s*;")
    gid_regex = Regexp.new("gid:\\s*#{self.gid}\\s*;")
    anygid_regex = /gid:\s*\d+\s*;/

    tmp.rewind
    File.open(filename, 'wt') do |rulefile|
      written = false
      tmp.each_line do |line|
        gid_matched = (gid_regex =~ line) || !(anygid_regex =~ line)
        if self.gid && self.sid && gid_matched && (sid_regex =~ line)
          rulefile.puts(self.rule_content)
          written = true
        else
          rulefile.puts(line)
        end
      end

      rulefile.puts(self.rule_content) unless written
    end
    tmp.close!

    true
  end

  # Check rule_content into CVS and update rule record.
  #
  # Write rule_content to file by calling patch.
  # Call CVS checkin.
  # Since CVS has a rewrite rule for checkins, update rule record from file.
  def checkin
    filename = self.filename || self.rule_category.filename(self.gid)

    patch(filename)
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
      rule.edit_status = EDIT_STATUS_SYNCHED
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
    EDIT_STATUS_SYNCHED == edit_status
    # %w[UNCHANGED].include?(state)
  end

  # Tests if edited rule is new
  # @return [boolean] true iff rule is a new edited rule
  def new_rule?
    EDIT_STATUS_NEW == edit_status
    # draft? && sid.nil?
  end

  # Tests if edited rule is an edited update to an existing rule
  # @return [boolean] true iff rule is a updated edited rule
  def edited_rule?
    EDIT_STATUS_EDIT == edit_status
    # draft? && sid.present?
  end

  # Tests if rule is a user edited version
  # @return [boolean] true iff rule is a user edited version
  def draft?
    new_rule? || edited_rule?
    # %w[NEW UPDATED FAILED].include?(state)
  end

  # Tests if edited rule is in progress while VC updated the rule externally
  # @return [boolean] true iff rule is a updated edited rule but VC has not changed
  def current_edit?
    PUBLISH_STATUS_CURRENT_EDIT == publish_status
  end

  # Tests if edited rule is in progress while VC updated the rule externally
  # @return [boolean] true iff rule is a updated edited rule and VC has updated the rule
  def stale_edit?
    PUBLISH_STATUS_STALE_EDIT == publish_status
  end

  # Tests if edited rule is in progress while VC updated the rule externally
  # @return [boolean] true iff rule is a updated edited rule and VC has updated the rule
  def publishing?
    PUBLISH_STATUS_PUBLISHING == publish_status
  end

  # The CSS class identifiers to identify the type of rule this is.
  #
  # Used for stylesheet styling.
  # synched      | rule is up to date with VC
  # edited-rule  | rule has been changed by a user and has not been committed to VC
  # current-edit | edited-rule and can be commited to VC
  # stale-edit   | edited-rule but VC has been updated externally and we cannot commit the change
  # new-rule     | rule is newly created by a user and not commited to VC
  # draft        | new-rule or edited-rule
  # parsed       | draft parsed correctly in
  # failed       | new-rule or edited-rule
  # @returns [String] the CSS class name(s), space delimited if multiple
  def css_class
    [].tap do |css_classes|
      css_classes << 'synched' if synched?
      css_classes << 'draft' if draft?
      css_classes << 'new-rule' if new_rule?
      css_classes << 'edited-rule' if edited_rule?
      css_classes << 'current-edit' if current_edit?
      css_classes << 'stale-edit' if stale_edit?
      css_classes << 'parsed' if parsed?
      css_classes << 'failed' unless parsed?
    end.join(' ')
  end

  def self.create_rule_action(bug_id, rule_content)
    rule = Rule.save_rule_content(rule_content)
    # rule.save

    # bug = Bug.where(id: bug_id).first
    # bug.rules << rule
  end

  def self.update_rule_action(rule_id, rule_content, rule_doc)
    Rule.save_rule_content(rule_content, rule_id).tap do |rule|
      rule.update_references(permitted_params[:rule][:rule_content])
      if rule.rule_doc.present?
        rule.rule_doc.update(permitted_params[:rule][:rule_doc])
      else
        rule.create_rule_doc(permitted_params[:rule][:rule_doc])
      end
    end
  end
end
