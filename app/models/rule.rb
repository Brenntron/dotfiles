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
#     * committing          |nil|   NEW   |    NEW    |  PUBLISHING  | true | the rule is in the process of being commited.
#   * edit
#     * current edit
#       * valid             |int| UPDATED |   EDIT    | CURRENT_EDIT | true | CVS rule edited in UI or web service
#       * failed parse      |int|  FAILED |   EDIT    | CURRENT_EDIT |false | edited rule which failed visruleparse
#       * committing        |int| UPDATED |   EDIT    |  PUBLISHING  | true | the rule is in the process of being commited.
#     * out of date
#       * valid             |int| UPDATED |   EDIT    |  STALE_EDIT  | true | edited rule, but CVS has since been updated and cannot save
#       * failed parse      |int|  FAILED |   EDIT    |  STALE_EDIT  |false | stale edit which failed visruleparse
#
class Rule < ApplicationRecord
  has_paper_trail

  belongs_to :rule_category, optional: true

  has_and_belongs_to_many :bugs
  has_and_belongs_to_many :references, dependent: :destroy
  accepts_nested_attributes_for :references
  has_many :test_reports
  has_many :tasks, through: :test_reports
  has_one :rule_doc, dependent: :destroy

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

  scope :by_sid, ->(sid, gid = 1) { where(sid: sid).where(gid: gid || 1) }

  def deleted?
    rule_category && rule_category.deleted?
  end

  def has_doc?
    rule_doc && rule_doc.summary.present?
  end

  # determines if the rule *should* be on (uncommented) or off (commented)
  # @return [Boolean] true if it should be on
  def should_be_on?
    case
      when /policy balanced-ips/ =~ self.metadata
        true
      when /policy connectivity-ips/ =~ self.metadata
        true
      when /flowbits\s*:\s*set\s*,/ =~ self.detection
        true
      else
        false
    end
  end

  # the rule content uncommented (if a # it is omitted)
  # @return [String] the rule content uncommented
  def on_rule_content(rule_content_given = nil)
    local_rule_content = rule_content_given || self.rule_content
    local_rule_content.sub(/^\s*#?\s*/, '')
  end

  # the rule content commented (with a #)
  # @return [String] the rule content commented
  def off_rule_content(rule_content_given = nil)
    local_rule_content = rule_content_given || self.rule_content
    local_rule_content.sub(/^\s*#?\s*/, '# ')
  end

  def test_rule_content
    rule_string = on_rule_content
    if new_rule?
      rule_string.gsub!(/\)\s*\z/, " gid:#{self.gid || 1};)") unless /gid:\s*\d+\s*;/ =~ rule_string
      new_sid = id + SnortLocalRulesResultProcessor::NEW_RULE_ID_BIAS
      rule_string.gsub!(/\)\s*\z/, " sid:#{new_sid};)") unless /sid:\s*\d+\s*;/ =~ rule_string
      rule_string.gsub!(/\)\s*\z/, " rev:1;)") unless /rev:\s*\d+\s*;/ =~ rule_string
    end
    rule_string
  end

  # the rule content in the correct on/off commented/uncommented state to commit
  # @return [String] the corrected rule content
  def rule_content_for_commit
    if should_be_on?
      update(rule_content: on_rule_content, on: true)
      on_rule_content
    else
      update(rule_content: on_rule_content, on: false)
      off_rule_content
    end
  end

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

  def self.gid_regexp(gid)
    Regexp.new("gid:\\s*#{gid}\\s*;")
  end

  def self.anygid_regexp
    @anygid_regexp ||= /gid:\s*\d+\s*;/
  end

  def self.grep_line_from_file(sid, gid, given_filepath = nil)
    filepath = given_filepath || "#{Rails.root}/extras/snort/*/*.rules"
    rule_grep_output = `grep -Hn "sid:\\s*#{sid}\\s*;" #{filepath}`
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

  def rule_classification
    if self.class_type
      impact = self.class_type.scan(/[a-z-]/).join
      RulesHelper::CLASSIFICATION[impact]
    else
      nil
    end
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

  def associate_references(rule_content)
    references_ary = []
    rule_content.split(';').each { |r| references_ary << r.strip.gsub!('reference:', '') if r.match(/reference\W*:/) }

    self.references.delete_all
    references_ary.each do |r|
      r = r.split(',')
      unless r[1].nil? || r[1].empty?
        ref_type = ReferenceType.find_or_create_by(name: r[0].strip)
        new_reference = Reference.find_or_create_by(reference_type: ref_type, reference_data: r[1].strip)
        self.references << new_reference
      end
    end
  end

  def update_references(rule_content)
    current_references = []
    references.each { |r| current_references << ReferenceType.where(id: r.reference_type_id).first.name + ',' + r.reference_data }
    references = []
    rule_content.split(';').each { |r| references << r.strip.gsub!('reference:', '') if r.match(/reference\W*:/) }
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

  # Extracts components from VisruleParser and sets field of rule.
  #
  # Does not save the rule.
  # Does not set state, edit_status, or publish_status,
  # because these depend on where the rule and rule_content originated.
  # @param [VisruleParser, #read] parser initialized to rule content.
  def assign_from_visrule(given_rule_content)
    self.on                             = /^\s*#/ !~ given_rule_content
    self.rule_content                   = on_rule_content(given_rule_content)

    vparser = RuleSyntax::VisruleParser.new(on_rule_content)

    self.rule_parsed                    = vparser.parsed_lines
    self.rule_warnings                  = vparser.errors

    self.parsed                         = vparser.valid?
    self.committed                      = !vparser.valid?

    if parsed?
      self.rule_failures                = nil
    else
      self.rule_failures                = vparser.parsed_lines
    end

    self
  end

  PARSE_QUALITY_ALL_CLEAR               = 100
  PARSE_QUALITY_VALID                   =  70
  PARSE_QUALITY_IS_A_RULE               =  20
  PARSE_QUALITY_CONTENT_HAS_SID         =  15
  PARSE_QUALITY_CONTENT_PRESENT         =  10
  PARSE_QUALITY_NO_CONTENT              =   5
  PARSE_QUALITY_NOT_AVAILABLE           =   0

  # @return [Integer] different levels of validity, for documentation if nothing else.
  def parse_quality
    vparser = RuleSyntax::VisruleParser.new(on_rule_content)

    case
      when !rule_content || !rule_parsed
        PARSE_QUALITY_NOT_AVAILABLE
      when vparser.all_clear?
        PARSE_QUALITY_ALL_CLEAR
      when vparser.valid?
        PARSE_QUALITY_VALID
      when vparser.is_a_rule?
        PARSE_QUALITY_IS_A_RULE
      when /sid:\s*\d+\s*;/ =~ rule_content
        PARSE_QUALITY_CONTENT_HAS_SID
      when vparser.has_rule_content?
        PARSE_QUALITY_CONTENT_PRESENT
      else
        PARSE_QUALITY_NO_CONTENT
    end
  end

  # assings fields from attributes output of parser
  #
  # calls assign_attributes.
  # does not save rule.
  # @param [Hash, #read]
  def assign(attributes)
    assign_attributes(attributes.slice(*%i(rev message connection flow detection class_type metadata message)))
    self.rule_category = RuleCategory.find_or_create_by(category: attributes[:rule_category])
    self.attributes
  end

  # Does a robust query or create new rule.
  #
  # Finds a rule from the sid and gid of parser, or optionally the rule id.
  # Returns new rule if none is found.
  # Does not change or save the rule.
  # @param [RuleSyntax::RuleParser, #read] parser constructed from the rule_content
  # @param [Integer, #read] rule_id the rule id if known
  def self.find_from_parser(parser, rule_id = nil)
    rule = nil
    rule = Rule.by_sid(parser.sid, parser.gid).first if parser.sid
    rule ||= Rule.where(id: rule_id).first if rule_id
    rule ||= Rule.new(sid: parser.sid, gid: parser.gid)

    rule
  end

  # Take a line from a user edit and saves to database
  # @param [String, #read] rule_content the rule content
  # @param [Integer, #read] rule_id the rule id if known
  def self.save_rule_content(rule_content, rule_id = nil)
    parser = RuleSyntax::RuleParser.new(rule_content)

    find_from_parser(parser, rule_id).tap do |rule|
      rule.assign_from_visrule(rule_content)
      rule.assign(parser.attributes)

      if rule.sid
        rule.state                        = 'UPDATED'
        rule.edit_status                  = EDIT_STATUS_EDIT
      else
        rule.state                        = 'NEW'
        rule.edit_status                  = EDIT_STATUS_NEW
      end
      rule.state                          = 'FAILED' unless rule.parsed?
      rule.publish_status                 = PUBLISH_STATUS_CURRENT_EDIT unless rule.stale_edit?

      rule.save!
    end
  end

  # Forces a load of the rule from the rule_content.
  # Assumed to be loaded from a rules file (either a synch or revert).
  # @param [String, #read] rule_content
  def load_rule_content(rule_content)
    parser = RuleSyntax::RuleParser.new(rule_content)

    assign_from_visrule(rule_content)

    assign(parser.attributes)

    self.cvs_rule_content               = self.rule_content
    self.cvs_rule_parsed                = self.rule_parsed

    self.edit_status                    = EDIT_STATUS_SYNCHED
    self.publish_status                 = PUBLISH_STATUS_SYNCHED
    self.state                          = 'UNCHANGED'
    self.save!
    self.associate_references(rule_content)
    self
  end

  # Take a line from a rule file and saves to database if rule is unedited
  # Assumes rule content comes from synching VC.
  # @param [String, #read] rule_content the line of text from a rule file.
  # @return [Rule] the rule loaded or nil if failed
  # @raise [RuntimeError] could not process
  def self.synch_rule_content(rule_content)
    parser = RuleSyntax::RuleParser.new(rule_content)
    return nil unless parser.sid          # rule in file is a new rule with sid unassigned

    rule_db = by_sid(parser.sid, parser.gid).first

    if rule_db && rule_db.draft?
      rule_db.update(publish_status: PUBLISH_STATUS_STALE_EDIT)
      rule_db
    else
      rule = find_from_parser(parser)
      rule.load_rule_content(rule_content)
      rule
    end
  end

  # loads an rule content from a line in a rule file
  # Skips lines without sid and where we have a rule with that rev
  # @param [String] line from rule file
  def self.load_line(line)
    if /sid:\s*(?<sid>\d+)\s*;/ =~ line
      /gid:\s*(?<gid>\d+)\s*;/ =~ line
      /rev:\s*(?<rev>\d+)\s*;/ =~ line

      rule = Rule.by_sid(sid, gid || 1).first
      if rule && (rev.to_i > rule.rev)
        rule.load_rule_content(line)
      end
    end
  end

  # Looks up rule from rule_content or creates a new rule object.
  #
  # Finds a rule from the sid and gid of parser.
  # Returns new rule if none is found.
  # Saves the rule.
  # @param [String, #read]  rule_content
  # @return [Rule] A rule object for the rule content.
  def self.find_and_load_rule_content(rule_content)
    parser = RuleSyntax::RuleParser.new(rule_content)
    rule = Rule.find_from_parser(parser)
    rule.load_rule_content(rule_content)
    rule
  end

  # Take a line from grep output of a rule file and saves to database
  # @param [String, #read] rule_grep_line the line of text from a rule file.
  # @return [Rule] the rule loaded, nil if failed, empty string if input was blank
  # @raise [RuntimeError] could not process
  def revert_grep(rule_grep_line)
    filename, line_number, rule_content = rule_grep_line.partition(/:\d+:/)

    rule_content.strip!
    if rule_content.empty?
      nil
    else
      load_rule_content(rule_content).tap do |rule|
        rule.update!(filename: filename, linenumber: line_number[1..-2].to_i)
      end
    end
  end

  # Take a line from grep output of a rule file and saves to database
  # @param [String, #read] rule_grep_line the line of text from a rule file.
  # @return [Rule] the rule loaded, nil if failed, empty string if input was blank
  # @raise [RuntimeError] could not process
  def self.load_grep(rule_grep_line)
    filename, line_number, rule_content = rule_grep_line.partition(/:\d+:/)
    filename = nil if /[-\/\w]+/ !~ filename

    rule_content.strip!
    if rule_content.empty?
      nil
    else
      synch_rule_content(rule_content).tap do |rule|
        if rule && !rule.stale_edit?
          rule.update!(filename: filename, linenumber: line_number[1..-2].to_i)
        end
      end
    end
  end

  def self.find_or_load(sid, gid)
    Rule.by_sid(sid, gid).first || load_grep(grep_line_from_file(sid, gid))
  end

  # A filename which will not be nil
  # The filename field may be nil.  If so determine the path from rule_category
  # @return [Pathname] check this and related records for pathname
  def nonnil_pathname
    @nonnil_pathname ||= Pathname.new(self.filename || self.rule_category.filename(self.gid))
  end

  # Replace rule in given file with rule_content.
  # Scans file for rule with same gid and sid and replaces that line with rule_content.
  # Appends rule_content to end of file if gid and sid are not found
  # @param [String, #read] path to the file.
  def patch_file(filename)
    tmp = Tempfile.new(['tmprule', '.rules'])
    File.open(filename, 'rt') do |input_stream|
      IO.copy_stream(input_stream, tmp)
    end

    sid_regex = Regexp.new("sid:\\s*#{self.sid}\\s*;")
    gid_regex = Regexp.new("gid:\\s*#{self.gid}\\s*;")

    tmp.rewind
    File.open(filename, 'wt') do |rulefile|
      written = false
      tmp.each_line do |line|
        gid_matched = (gid_regex =~ line) || !(Rule.anygid_regexp =~ line)
        if self.gid && self.sid && gid_matched && (sid_regex =~ line)
          rulefile.puts(rule_content_for_commit)
          written = true
        else
          rulefile.puts(line)
        end
      end

      rulefile.puts(rule_content_for_commit) unless written
    end
    tmp.close!

    true
  end

  def update_rule
    begin
      rule = Rule.find_rule(Rule.find(params[:id]).sid) # This will update if found
      rule.state = "UNCHANGED"
      rule.attachments.clear
      rule.save(validate: false)

    rescue Exception => e
      log_error(e)
    rescue RuleError => e
      add_error("#{rule.sid}: #{e}")
    end

    redirect_to request.referer
  end

  def self.find_current_rule(sid)
    Dir.entries(Rails.configuration.snort_rule_path).each do |f|
      # Don't include .stub.rules hidden rule files
      if f =~ /^[^\.]/ && f =~ /\.rules$/
        File.read("#{Rails.configuration.snort_rule_path}/#{f}").each_line do |line|
          line = line.chomp.gsub(/^# /, '')

          if line =~ /sid:\s*#{sid}\s*;/
            return line
          end
        end
      end
    end

    raise RuleError.new("Unable to find sid #{sid}")
  end

  def build_rule_params(rule_data)
    rule_params = {}
    rule_params['sid'] = sid
    rule_params['gid'] = gid
    rule_params['rev'] = rev
    rule_params['connection'] = connection
    rule_params['msg'] = message
    rule_params['flow'] = flow
    rule_params['class_type'] = class_type
    rule_params['detection'] = detection
    rule_params['metadata'] = metadata

    reference_data = rule_data['references']
    rule_params['references'] = reference_data.map do |reference_datum|
      "reference:#{reference_datum['reference_type']},#{reference_datum['reference_data']}; "
    end.join

    rule_params
  end

  def update_parts(rule_data)
    rule_params = build_rule_params(rule_data)
    rule_content_local = RuleSyntax::Assemposer.new(rule_params).rule_content
    Rule.save_rule_content(rule_content_local)
    associate_references(rule_content_local)
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
  end

  # Tests if edited rule is new
  # @return [boolean] true iff rule is a new edited rule
  def new_rule?
    EDIT_STATUS_NEW == edit_status
  end

  # Tests if edited rule is an edited update to an existing rule
  # @return [boolean] true iff rule is a updated edited rule
  def edited_rule?
    EDIT_STATUS_EDIT == edit_status
  end

  # Tests if rule is a user edited version
  # @return [boolean] true iff rule is a user edited version
  def draft?
    new_rule? || edited_rule?
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
  # @return [String] the CSS class name(s), space delimited if multiple
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

  # Creates a rule and its associations
  # @return [Rule]
  def self.create_action(rule_content, rule_doc, bug_id)
    Rule.save_rule_content(rule_content).tap do |rule|
      if bug_id
        bug = Bug.where(id: bug_id).first
        bug.rules << rule if bug
      end

      rule.associate_references(rule_content)
      rule.create_rule_doc(rule_doc)
    end
  end

  # Creates a rule and its associations
  # @return [Rule]
  def self.create_parts_action(rule_params, rule_doc, bug_id)
    Rule.save_rule_content(RuleSyntax::Assemposer.new(rule_params).rule_content).tap do |rule|
      if bug_id
        bug = Bug.where(id: bug_id).first
        bug.rules << rule if bug
      end

      rule.associate_references(rule.rule_content)
      rule.create_rule_doc(rule_doc)
    end
  end

  def self.revert_rules_action(rule_ids)
    rule_ids.each do |id|
      rule = Rule.where(id: id).first
      rule.revert_grep(Rule.grep_line_from_file(rule.sid, rule.gid, rule.filename))
      rule.rule_doc.revert_doc if rule.rule_doc
    end

    true
  rescue
    false
  end

  # Updates a rule and its associations
  # @return [Rule]
  def self.update_action(rule_id, rule_content, rule_doc)
    Rule.save_rule_content(rule_content, rule_id).tap do |rule|
      rule.update_references(rule_content)
      if rule.rule_doc.present?
        rule.rule_doc.update(rule_doc)
      else
        rule.create_rule_doc(rule_doc)
      end
    end
  end

  def self.update_parts_action(sid, gid, rule_data)
    puts "*** rule_data = #{rule_data.inspect}"
    byebug
    raise 'raspberry' if true
    rule = Rule.by_sid(sid, gid).first
    rule.update_parts(rule_data)
  end
end
