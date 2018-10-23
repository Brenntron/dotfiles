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
#     * failed parse        |nil| FAILED  |    NEW    | CURRENT_EDIT |false | new rule which failed visruleparse
#     * committing          |nil|   NEW   |    NEW    |  PUBLISHING  | true | the rule is in the process of being commited.
#   * edit
#     * current edit
#       * valid             |int| UPDATED |   EDIT    | CURRENT_EDIT | true | CVS rule edited in UI or web service
#       * failed parse      |int| FAILED  |   EDIT    | CURRENT_EDIT |false | edited rule which failed visruleparse
#       * committing        |int| UPDATED |   EDIT    |  PUBLISHING  | true | the rule is in the process of being commited.
#     * out of date
#       * valid             |int|  STALE  |   EDIT    |  STALE_EDIT  | true | edited rule, but CVS has since been updated and cannot save
#       * failed parse      |int|  STALE  |   EDIT    |  STALE_EDIT  |false | stale edit which failed visruleparse
#
# snort_doc_status
#   Rules start in NOT_YET_PUB status.
#   When rules are published to snort, they are marked as TO_BE_PUB.
#   Except rules set as SUPRESS will not be set to TO_BE_PUB.
#   Docs are generated from *all* TO_BE_PUB, including manually set.
#   When generated docs are uploaded to snort.org the rules are set to BEEN_PUB.
#
class Rule < ApplicationRecord
  has_paper_trail

  belongs_to :rule_category, optional: true

  has_many :bugs_rules
  has_many :bugs, through: :bugs_rules
  has_many :bug_reference_rule_links, as: :link
  has_many :references, through: :bug_reference_rule_links

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
  PUBLISH_STATUS_PUBLISHING     = 'PUBCONTENT'      #draft in process of rule content being written to VC
  PUBLISH_STATUS_PUBDOC         = 'PUBDOC'          #draft in process of rule docs being written to VC

  UNCHANGED_STATE               = 'UNCHANGED'
  UPDATED_STATE                 = 'UPDATED'
  NEW_STATE                     = 'NEW'
  STALE_STATE                   = 'STALE'           #is set to stale when publish status is set to stale
  FAILED_STATE                  = 'FAILED'
  DELETED_STATE                 = 'DELETED'

  DOC_STATUS_UPDATED            = 'UPDATED'
  DOC_STATUS_SYNCHED            = 'SYNCHED'

  SNORT_DOC_STATUS_SUPRESS      = 'SUPRESS'
  SNORT_DOC_STATUS_NOT_YET_PUB  = 'NOTYET'
  SNORT_DOC_STATUS_TO_BE_PUB    = 'TOBE'
  SNORT_DOC_STATUS_BEEN_PUB     = 'BEEN'
  SNORT_DOC_STATUSES            =
      [
          SNORT_DOC_STATUS_SUPRESS,
          SNORT_DOC_STATUS_NOT_YET_PUB,
          SNORT_DOC_STATUS_TO_BE_PUB,
          SNORT_DOC_STATUS_BEEN_PUB,
      ]

  # Pre-commit hook intercepted commit, failed it, and successfully checked in the rule
  SVN_SUCCESS_COMMIT_HOOK = 199
  
  # Scope that ensures no deleted rules show up in a query. This scope should be used whenever displaying rules.
  #removing scope until data error has been corrected
  # scope :active, -> { joins(:rule_category).where('rule_categories.category != ?', 'DELETED') }

  scope :by_sid, ->(sid, gid = 1) { where(sid: sid).where(gid: gid || 1) }
  scope :order_by_sid, -> { order(:gid, :sid) }

  scope :with_pub_content, -> { where(publish_status: PUBLISH_STATUS_PUBLISHING) }
  scope :with_pub_doc, -> { where(publish_status: PUBLISH_STATUS_PUBDOC) }
  scope :with_pub_any, -> { where(publish_status: [PUBLISH_STATUS_PUBLISHING, PUBLISH_STATUS_PUBDOC]) }

  unless Rails.env.production? || Rails.env.staging?
    validates_with NewRuleValidator, EditedRuleValidator, SynchedRuleValidator, SnortRuleValidator
  end

  def svn_success?
    SVN_SUCCESS_COMMIT_HOOK == self.svn_result_code
  end

  def deleted?
    rule_category&.deleted?
  end

  def requires_doc?
    case
      when rule_category.blank?
        false
      else
        rule_category.requires_doc?
    end
  end

  def doc_template_name
    case
      when RuleCategory.policy_categories.include?(rule_category)
        'policy'
      when RuleCategory.malware_categories.include?(rule_category)
        'malware'
      when bugs.joins(:tags).where(tags: {name: 'VD'}).exists?
        'truffle'
      when references.cves.exists?
        'cve'
      else
        'general'
    end
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

  def content_same?
    (!new_rule?) && (cvs_rule_content == rule_content)
  end

  def content_changed?
    new_rule? || (cvs_rule_content != rule_content)
  end

  def display_alerts_count(bug)
    if synched_rule?
      "#{bug.pcap_alerts.by_rule(self).count}"
    else
      "#{bug.local_alerts.by_rule(self).count}"
    end
  end

  def display_alerts(bug)
    if synched_rule?
      bug.pcaps.left_pcap_test(self).map do |pcap|
        {
            pcap_id: pcap.id,
            file_name: pcap.file_name,
            alert_status: (pcap.rule_id ? 'alerted' : 'clear'),
            direct_upload_url: pcap.direct_upload_url
        }
      end
    else
      bug.pcaps.left_local_test(self).map do |pcap|
        {
            pcap_id: pcap.id,
            file_name: pcap.file_name,
            alert_status: (pcap.rule_id ? 'alerted' : 'clear'),
            direct_upload_url: pcap.direct_upload_url
        }
      end
    end
  end

  def tested_on_bug?(bug)
    self.synched_rule? || bugs_rules.select{|b| b.bug_id == bug.id && b.tested == true }.present?
  end

  def test_rule_content
    rule_string = on_rule_content
    if new_rule?
      rule_string = rule_string.gsub(/\)\s*\z/, " gid:#{self.gid || 1};)") unless /gid:\s*\d+\s*;/ =~ rule_string
      new_sid = id + SnortLocalRulesResultProcessor::NEW_RULE_ID_BIAS
      rule_string = rule_string.gsub(/\)\s*\z/, " sid:#{new_sid};)") unless /sid:\s*\d+\s*;/ =~ rule_string
      rule_string = rule_string.gsub(/\)\s*\z/, " rev:1;)") unless /rev:\s*\d+\s*;/ =~ rule_string
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

  def clear_svn_result
    update(svn_result_output: nil, svn_result_code: nil, svn_success: nil)
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

  # Greps the snort dir for rules
  # Does a recursive grep
  # which can find snort (text) rules (gid=1), so rules (gid=3) or preprocessor rules.
  # This is only limited by what is on the file system and qualified by a gid argument.
  #
  # Returns nil if no matching rule is found.  Raises exception if more than one matching rule is found
  #
  # @param [Integer] sid
  # @param [Integer|NilClass] gid or nil for either gid 1 or 3
  # @param [String] given_filepath if not the default filepath
  # @return [String|NilClass] grep output with filename colon linenumber colon rule content.
  def self.grep_line_from_file(sid, gid = nil, given_filepath = nil)
    filepath = given_filepath || "#{Rails.root}/extras/snort/*/*.rules"
    rule_grep_output = `grep -Hn "sid:[ ]*#{sid}[ ]*;" #{filepath}`
    rule_grep_lines = rule_grep_output.split("\n").select do |grep_line|
      case
        # asked for gid and found it
        when gid && (gid_regexp(gid) =~ grep_line)
          true

        # asked for gid 1 or 3, and found it
        when gid.nil? && (gid_regexp('[13]') =~ grep_line)
          true

        # found some other gid
        when gid && (anygid_regexp =~ grep_line)
          false

        # no gid in line, and asked for gid 1
        when (1 == gid) || gid.nil?
          true

        # no gid in line, and wasn't asking for gid 1
        else
          false
      end
    end

    raise "Duplicate rules found for sid #{sid}." if 1 < rule_grep_lines.length

    if 0 == rule_grep_lines.length
      nil
    else
      rule_grep_lines[0]
    end
  end

  # Greps the snort dir for rules
  # Does a recursive grep
  # which can find snort (text) rules (gid=1), so rules (gid=3) or preprocessor rules.
  # This is only limited by what is on the file system and qualified by a gid argument.
  #
  # Raises exception if no matching rule is found.
  # Raises exception if more than one matching rule is found
  #
  # @param [Integer] sid
  # @param [Integer|NilClass] gid or nil for either gid 1 or 3
  # @param [String] given_filepath if not the default filepath
  # @return [String] grep output with filename colon linenumber colon rule content.
  def self.grep_line_from_file!(sid, gid = nil, given_filepath = nil)
    grep_line_from_file(sid, gid, given_filepath) ||
        grep_line_from_file(sid, nil, nil) ||
        raise("Rule #{sid} doesn't exist.")
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
    self.fatal_errors                   = vparser.fatal_errors

    self.parsed                         = vparser.valid?
    self.committed                      = !vparser.valid?

    self.rule_failures =
        case
          when parsed?
            nil
          when self.fatal_errors.present?
            'FAILED: visruleparser error.'
          else
            vparser.parsed_lines
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
  def assign_from_parser(attributes)
    assign_attributes(attributes.slice(*%i(gid sid rev message connection flow detection class_type metadata message)))
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

  # Take a line from a user edit and assign the rule state
  # @param [String, #read] rule_content the rule content
  # @param [RuleSyntax::RuleParser, #read] parser a standard parser constructed from the rule_content
  def assign_from_user_edit(rule_content, parser:)
    assign_from_visrule(rule_content)
    assign_from_parser(parser.attributes)

    case
      when sid.nil?
        self.edit_status                = EDIT_STATUS_NEW
        self.state                      = NEW_STATE
      when !content_changed?
        self.edit_status                = EDIT_STATUS_SYNCHED
        self.state                      = UNCHANGED_STATE
        self.rule_parsed                = self.cvs_rule_parsed
      else
        self.edit_status                = EDIT_STATUS_EDIT
        self.state                      = UPDATED_STATE
    end

    self.state                          = FAILED_STATE unless parsed?

    self.publish_status                 = PUBLISH_STATUS_CURRENT_EDIT unless stale_edit?

    if deleted?
      self.state                        = DELETED_STATE
    end

    self.doc_status                     = DOC_STATUS_UPDATED
  end

  # Take a line from a rule file and assign the rule state
  # @param [String, #read] rule_content the rule content
  def assign_from_rule_file(rule_content)
    parser = RuleSyntax::RuleParser.new(rule_content)

    assign_from_visrule(rule_content)

    assign_from_parser(parser.attributes)

    self.cvs_rule_content               = self.rule_content
    self.cvs_rule_parsed                = self.rule_parsed

    self.edit_status                    = EDIT_STATUS_SYNCHED
    self.publish_status                 = PUBLISH_STATUS_SYNCHED
    if self.deleted?
      self.state                          = DELETED_STATE
    else
      self.state                          = UNCHANGED_STATE
    end
  end

  # Take a line from a user edit and saves to database
  # @param [String, #read] rule_content the rule content
  # @param [Integer, #read] rule_id the rule id if known
  def self.save_rule_content(rule_content, rule_id = nil)
    parser = RuleSyntax::RuleParser.new(rule_content)
    raise "Cannot parse rule content '#{rule_content}'" unless parser.well_formed?
    find_from_parser(parser, rule_id).tap do |rule|
      unless rule_content == rule.cvs_rule_content
        rule.assign_from_user_edit(rule_content, parser: parser)
        rule.bugs_rules.update_all(tested: false)
        rule.save!
        rule.clear_svn_result
      end
    end
  end

  # Forces a load of the rule from the rule_content.
  # Assumed to be loaded from a rules file (either a synch or revert).
  # @param [String, #read] rule_content
  def load_rule_content(rule_content, should_clear_svn_result: true)
    assign_from_rule_file(rule_content)
    save!
    clear_svn_result if should_clear_svn_result
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

    case
      when rule_db.nil?
        rule = find_from_parser(parser)
        rule.load_rule_content(rule_content)
        rule
      when rule_db.publishing_content?
        rule = find_from_parser(parser)
        rule.load_rule_content(rule_content)
        rule
      when rule_db.draft? && parser.rev > rule_db.rev
        rule_db.update(publish_status: PUBLISH_STATUS_STALE_EDIT, state: STALE_STATE)
        rule_db
      when rule_db.draft?
        # do nothing
        rule_db
      when rule_db.deleted?
        rule_db.update(state: DELETED_STATE)
        rule_db
      else
        rule = find_from_parser(parser)
        rule.load_rule_content(rule_content)
        rule
    end
  end

  def rev_matches?(rule_content)
    parser = RuleSyntax::RuleParser.new(rule_content)
    parser.rev == self.rev
  end

  def sid_colon_format
    if self.sid.nil?
      "No SID"
    else
      "#{self.gid}:#{self.sid}:#{self.rev}"
    end
  end

  def self.get_alert_css_class_for(has_untested_attachments, has_local_alerts)
    case
      when has_untested_attachments
        'untested'
      when has_local_alerts
        'alerted'
      else
        'no-alert'
    end
  end

  def self.get_alert_status_for(has_untested_attachments, has_local_alerts)
    case
      when has_untested_attachments
        'Untested'
      when has_local_alerts
        'Alerted'
      else
        'No alert'
    end
  end

  # Sets a rule or rules to a synched state
  #
  # @param [Rule|Relation] A single rule object or an ActiveRecord relation
  def self.set_synched_state(rule_arg)
    state_values = { publish_status: PUBLISH_STATUS_SYNCHED,
                     edit_status: EDIT_STATUS_SYNCHED,
                     state: UNCHANGED_STATE,
                     doc_status: DOC_STATUS_SYNCHED }

    case rule_arg
      when Rule
        rule_arg.update(state_values)
      else
        rule_arg.update_all(state_values)
    end
  end

  def self.set_pubcontent_state(rule_arg)
    case rule_arg
      when Rule
        rule_arg.update( publish_status: PUBLISH_STATUS_PUBLISHING )
      else
        rule_arg.update_all( publish_status: PUBLISH_STATUS_PUBLISHING )
    end
  end

  def self.set_pubdoc_state(rule_arg)
    state_values = { publish_status: PUBLISH_STATUS_PUBDOC,
                     state: UPDATED_STATE }

    case rule_arg
      when Rule
        rule_arg.update( state_values )
      else
        rule_arg.update_all( state_values )
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
        Rule.set_pubdoc_state(rule) if rule.publishing_content?
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
  def self.find_and_load_rule_content(rule_content, should_clear_svn_result: true)
    parser = RuleSyntax::RuleParser.new(rule_content)
    rule = Rule.find_from_parser(parser)
    rule.load_rule_content(rule_content, should_clear_svn_result: should_clear_svn_result)
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

  # Get a rule from the database or subversion if possible
  # Returns nil if not found.
  # Raises exception if more than one is found.
  # @param [Integer] sid
  # @param [Integer|NilClass] gid or nil for either gid 1 or 3
  # @return [Rule|NilClass] the rule found.
  def self.find_or_load(sid, gid = nil)
    rule_db =
        if gid
          Rule.by_sid(sid, gid).first
        else
          Rule.by_sid(sid, 1).first || Rule.by_sid(sid, 3).first
        end
    return rule_db if rule_db

    # commented to assume steady state of updated snort-rules directory
    # `#{RuleFile.svn_cmd} up #{Repo::RuleContentCommitter.synch_root.to_s}/snort-rules/`
    rule_grep_line = grep_line_from_file(sid, gid)
    return nil unless rule_grep_line
    load_grep(rule_grep_line)
  end

  # Get a rule from the database or subversion if possible
  # Raises exception if not found.
  # Raises exception if more than one is found.
  # @param [Integer] sid
  # @param [Integer|NilClass] gid or nil for either gid 1 or 3
  # @return [Rule] the rule found.
  def self.find_or_load!(sid, gid = nil)
    rule_db =
        if gid
          Rule.by_sid(sid, gid).first
        else
          Rule.by_sid(sid, 1).first || Rule.by_sid(sid, 3).first
        end
    rule_db || load_grep(grep_line_from_file!(sid, gid))
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
      case
        when reference_datum['reference_type_id'].present?
          reference_type = ReferenceType.where(id: reference_datum['reference_type_id']).first
          "reference:#{reference_type.name},#{reference_datum['reference_data']}; "
        when reference_datum['reference_type'].present?
          "reference:#{reference_datum['reference_type']},#{reference_datum['reference_data']}; "
        else
          next
      end
    end.join

    rule_params
  end

  def update_parts(rule_data)
    rule_params = build_rule_params(rule_data)
    rule_content_local = RuleSyntax::Assemposer.new(rule_params).rule_content
    Rule.save_rule_content(rule_content_local)
  end

  def sort_state_ordinal
    case (state)
      when DELETED_STATE
        val = 7
      when FAILED_STATE
        val = 1
      when NEW_STATE
        val = 2
      when STALE_STATE
        val = 3
      when UPDATED_STATE
        val = 4
      when UNCHANGED_STATE
        val = 6
      else
        val = 5
    end
    val
  end

  def <=> (rule)
    case
      when self.sort_state_ordinal != rule.sort_state_ordinal
        self.sort_state_ordinal <=> rule.sort_state_ordinal
      when self.sid && rule.sid
        self.sid <=> rule.sid
      when self.sid.nil?
        -1
      when rule.sid.nil?
        1
      else
        self.id <=> rule.id
    end
  end

  def synched_rule?
    EDIT_STATUS_SYNCHED == edit_status
  end

  # Tests if rule is the current version in VC
  # @return [boolean] true iff rule is latest version synced with VC
  def synched?
    (EDIT_STATUS_SYNCHED == edit_status) && (DOC_STATUS_SYNCHED == doc_status)
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

  def publishing_content?
    PUBLISH_STATUS_PUBLISHING == publish_status
  end

  def publishing_doc?
    PUBLISH_STATUS_PUBDOC == publish_status
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
      css_classes << 'synched' if synched_rule?
      css_classes << 'draft' if draft?
      css_classes << 'new-rule' if new_rule?
      css_classes << 'edited-rule' if edited_rule?
      css_classes << 'current-edit' if current_edit?
      css_classes << 'stale-edit' if stale_edit?
      css_classes << 'parsed' if parsed?
      css_classes << 'incomplete-unparsed' unless parsed?

      css_classes << 'deleted-rule' if deleted?

    end.join(' ')
  end

  def tool_tip
    tip_text = []

    if synched_rule?
      tip_text << ToolTip::SYNCHED
    end
    if draft?
      tip_text << ToolTip::DRAFT
    end
    if new_rule?
      tip_text << ToolTip::NEW_RULE
    end
    if edited_rule?
      tip_text << ToolTip::EDITED_RULE
    end
    if current_edit?
      tip_text << ToolTip::CURRENT_EDIT
    end
    if stale_edit?
      tip_text << ToolTip::STALE_EDIT
    end
    if parsed?
      tip_text << ToolTip::PARSED
    end
    if !parsed?
      tip_text << ToolTip::NOT_PARSED
    end
    if deleted?
      tip_text << ToolTip::DELETED
    end
     
    tip_text.join("    ")

  end

  # Creates a new rule from a copy of this rule.
  def new_copy_rule(attributes_arg = {})
    changed_attributes = attributes_arg
    references_arg = changed_attributes.delete('references')
    new_references = references_arg || self.references.map{|ref| ref.attributes}

    new_attributes = self.attributes.merge(changed_attributes)
    new_attributes['id'] = nil
    new_attributes['sid'] = nil
    new_attributes['rev'] = nil
    new_attributes['rule_content'] = nil
    new_attributes['rule_parsed'] = nil
    new_attributes['cvs_rule_content'] = nil
    new_attributes['cvs_rule_parsed'] = nil
    new_attributes['filename'] = nil
    new_attributes['linenumber'] = nil

    rule = Rule.new(new_attributes)

    rule_params = rule.build_rule_params({ 'references' => new_references })
    rule_content = RuleSyntax::Assemposer.new(rule_params).rule_content
    parser = RuleSyntax::RuleParser.new(rule_content)
    rule.assign_from_user_edit(rule_content, parser: parser)

    rule
  end

  def dup
    rule = Rule.new(self.attributes)
    rule.sid = nil
    rule.rev = nil
    references_input = self.references.map{|ref| ref.attributes}
    rule_params = rule.build_rule_params({ 'references' => references_input })
    rule.rule_content = RuleSyntax::Assemposer.new(rule_params).rule_content

    rule
  end

  def check_to_smtp
    errors = []

    errors << 'from to_client' unless flow.split(',').include?('to_client')

    errors.empty? ? '' : "Intended to covert to STMP\n#{errors.join("\n")}"
  end

  def to_smtp
    new_metadata = metadata.split(/\s*,\s*/).reject{|metadatum| /\Aservice\s+/ =~ metadatum}
    new_metadata << 'service smtp'

    new_flow = ['to_server'] + flow.split(/\s*,\s*/).reject{|flow_datum| 'to_client' == flow_datum}

    new_copy_rule('connection' => 'alert tcp $EXTERNAL_NET any -> $SMTP_SERVERS 25',
              'metadata' => new_metadata.join(', '),
              'flow' => new_flow.join(','))
  end

  # Creates a rule and its associations
  # @return [Rule]
  def self.create_action(rule_content, rule_doc, bug_id)
    Rule.save_rule_content(rule_content).tap do |rule|
      if bug_id
        bug = Bug.where(id: bug_id).first
        bug.rules << rule if bug
      end

      if rule_doc.present?
        rule_doc = RuleDoc.prepare_rule_doc_hash(rule_doc, rule)
      end

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

      if rule_doc.present?
        rule_doc = RuleDoc.prepare_rule_doc_hash(rule_doc, rule)
      end
      rule.create_rule_doc(rule_doc)
    end
  end

  def self.revert_rules_action(rules)
    rules.each do |rule|
      rule.revert_grep(Rule.grep_line_from_file!(rule.sid, rule.gid, rule.filename))
    end

    true
  rescue
    false
  end

  # Updates a rule and its associations
  # @return [Rule]
  def self.update_action(rule, rule_content, rule_doc = nil)
    Rule.save_rule_content(rule_content, rule.id).tap do |rule|

      if rule_doc.present?
        rule_doc = RuleDoc.prepare_rule_doc_hash(rule_doc, rule)
      end

      if rule.rule_doc.present?
        rule.rule_doc.update(rule_doc)
      else
        rule.create_rule_doc(rule_doc)
      end
    end
  end

  def self.update_parts_action(sid, gid, rule_data)
    rule = Rule.by_sid(sid, gid).first
    rule.update_parts(rule_data)
  end
end

