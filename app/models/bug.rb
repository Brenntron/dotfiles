class Bug < ApplicationRecord

  has_many :giblets
  has_many :tag_gibs, through: :giblets, source: :gib, source_type: 'Tag'
  has_many :reference_gibs, through: :giblets, source: :gib, source_type: 'Reference'
  has_paper_trail

  has_many :bugs_rules
  has_many :rules, through: :bugs_rules
  has_and_belongs_to_many :tags, dependent: :destroy
  has_and_belongs_to_many :whiteboards, dependent: :destroy
  belongs_to :user, optional: true
  belongs_to :committer, class_name: 'User', optional: true

  has_many :bug_reference_rule_links, as: :link
  has_many :references, through: :bug_reference_rule_links

  has_many :exploits, through: :references
  has_many :attachments, dependent: :destroy
  has_many :pcaps, -> { pcap }, class_name: 'Attachment'
  has_many :tasks, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :test_reports

  has_many :alerts, through: :attachments
  has_many :local_alerts, through: :attachments
  has_many :pcap_alerts, through: :attachments

  #self referential relationships
  ## for snort escalation bugs
  has_many :research_bug_links, :class_name => 'EscalationLink', :foreign_key => 'snort_escalation_bug_id'
  has_many :snort_research_bugs, :through => :research_bug_links
  has_many :escalation_bug_links, :class_name => 'EscalationLink', :foreign_key => 'snort_research_bug_id'
  has_many :snort_escalation_bugs, :through => :escalation_bug_links

  has_many :research_to_research_bugs, :class_name => 'SnortResearch', :foreign_key => 'bug_id'
  has_many :snort_research_to_research_bugs, :through => :research_to_research_bugs

  #blocking logic stuff
  has_many :snort_bug_blockees, :class_name => "BugBlocker", :foreign_key => 'snort_blocker_bug_id'
  has_many :snort_blocked_bugs, :through => :snort_bug_blockees

  has_many :snort_bug_blockers, :class_name => "BugBlocker", :foreign_key => 'snort_blocked_bug_id'
  has_many :snort_blocker_bugs, :through => :snort_bug_blockers


  accepts_nested_attributes_for :rules

  STATE_PENDING                         = 'PENDING'
  STATES_OPEN                           = %w{OPEN ASSIGNED REOPENED}
  STATES_CLOSED                         = %w{FIXED WONTFIX LATER INVALID DUPLICATE}
  STATES                                = [STATE_PENDING] + STATES_OPEN + STATES_CLOSED
  STATES_RESOLVED                       = %w{CLOSED RESOLVED VERIFIED}

  LIBERTY_CLEAR                         = "CLEAR"
  LIBERTY_EMBARGO                       = "EMBARGO"

  COMPONENTS                            = ["ClamAV Signatures", "Malware", "Malware FP", "Snort Rules", "SO Rules"]

  scope :open_bugs, -> { where('state in (?)', STATES_OPEN) }
  scope :closed, -> { where('state in (?)', STATES_CLOSED) }
  scope :pending, -> { where(state: STATE_PENDING) }
  scope :open_pending, -> {where('state in (?)', [STATE_PENDING] + STATES_OPEN)}
  scope :by_component, ->(component) { where('component = ?', component) }

  scope :permit_class_level, ->(class_level) { where("classification <= ? ", Bug.classifications[class_level]) }

  scope :research_bugs, -> { where(product: 'research') }
  scope :by_escalations, -> { where(:product => "escalations")}

  scope :research_product, -> { where(:product => "Research")}
  scope :escalation_product, -> { where(:product => "Escalations")}

  #determines if this is a research bug by checking the bugzilla product in our database
  def research_product?
    "Research" == self.product
  end

  #determines if this is an escalation bug by checking the bugzilla product in our database
  def escalation_product?
    "Escalations" == self.product
  end

  #determines if this is a research bug by inherited method in ResearchBug which returns true
  def research_bug?
    false
  end

  #determines if this is an escalation bug by inherited method in ResearchBug which returns true
  def escalation_bug?
    false
  end

  def snort_related_bugs(component)
     "escalation"==component ? self.snort_escalation_bugs :  self.snort_research_bugs | self.snort_research_to_research_bugs
  end

  attr_accessor :import_report

  def is_blocked?
    #blocked_by.any?
  end

  def blocked_by
    #if product == "Escalations"
    #  snort_research_escalations.select { |bug| bug.pending? }
    #end
  end

  def acknowledged?
    acknowledged
  end

  def pending?
    STATE_PENDING == self.state
  end

  def liberty_clear?
    LIBERTY_CLEAR == self.liberty
  end

  def liberty_embargo?
    LIBERTY_EMBARGO == self.liberty
  end

  def self.bug_result(search_mode, bug_search_id, bug_search_max)
    case
      when bug_search_max.present?
        Bug.where("id BETWEEN ? AND ?", bug_search_id, bug_search_max)
      when 'advanced' == search_mode
        Bug.where("id LIKE ?", "%#{bug_search_id}%")
      else
        #return Bug object for redirect to that bug
        Bug.where("id='#{bug_search_id}%'").first
    end
  end

  def initialize_report
    @import_report = {}
    @import_report[:new_rules] = []
    @import_report[:new_attachments] = []
    @import_report[:new_notes] = 0
    @import_report[:new_tags] = []
    @import_report[:new_refs] = []
  end

  def compile_import_report(initial_bug_state = nil)
    total_report = @import_report.clone
    if initial_bug_state.present?


      bug_changes = self.changes
      bug_changes.keys.each do |key|
        if ['committer_id', 'user_id'].include?(key)
          before_user = User.where(:id => bug_changes[key].first).first
          after_user = User.where(:id => bug_changes[key].last).first

          if before_user.present? && after_user.present?
            bug_changes[key] = [before_user.cvs_username, after_user.cvs_username]
          end
        end
      end

      bug_changes.delete("research_notes")

      if bug_changes.has_key?("whiteboard")
        if bug_changes["whiteboard"].first.blank? && bug_changes["whiteboard"].last.blank?
          bug_changes.delete("whiteboard")
        end
      end


      total_report[:changed_bug_columns] = bug_changes
    end
    total_report[:total_changes] = total_report[:new_rules].count + total_report[:new_attachments].count + total_report[:new_notes] + total_report[:new_tags].count + total_report[:new_refs].count + total_report[:changed_bug_columns].size
    total_report
  end

  # @return [Array] username (displayable) and id pairs suitable for select drop downs.
  def allowed_assignees
    User.allowed_assignees(self).pluck(:cvs_username,:id)
  end

  # @return [Array] username (displayable) and id pairs suitable for select drop downs.
  def allowed_committers
    User.allowed_committers(self).pluck(:cvs_username,:id)
  end

  enum classification: {
                          unclassified: 0,
                          confidential: 1,
                          secret: 2,
                          top_secret: 3,
                          top_secret_sci: 4
                        }

  #after_create { |bug| bug.record 'create' if Rails.configuration.websockets_enabled == 'true' }
  #after_update { |bug| bug.record 'update' if Rails.configuration.websockets_enabled == 'true' }
  #after_destroy { |bug| bug.record 'destroy' if Rails.configuration.websockets_enabled == 'true' }

  def attachment_local_alerts(rule)
    pcaps.joins("LEFT OUTER JOIN alerts ON alerts.attachment_id = attachments.id and alerts.test_group = '#{Alert::TEST_GROUP_LOCAL}' and alerts.rule_id = #{rule.id}")
        .select(:file_name, 'alerts.rule_id', 'id')
  end

  def has_due_date?
    due_date.present?
  end

  def has_notes?
    notes.exists?
  end

  def has_published_notes?
    notes.published.exists?
  end

  def current_committer_note
    self.notes.where(note_type: "committer").last
  end

  def publish_note_to_bugzilla(bug_factory, **options)
    Note.process_note(options.merge(id: bugzilla_id), bug_factory)
  end

  def copy_notes_to_bug(bugzilla_id, bug_factory:)
    bug = Bug.where(bugzilla_id: bugzilla_id).first

    if bug
      self.notes.each do |note|
        bug.publish_note_to_bugzilla(bug_factory, comment: note.comment, note_type: note.note_type, author: note.author)
      end

      true
    end
  end

  def rule_relevant_references
    self.references.select {|ref| ReferenceType.valid_reference_type_ids.include?(ref.reference_type_id) }
  end

  def due_date
    self.tags.each do |tag|
      date = Date.parse(tag.name) rescue nil
      if date.present?
        return date.to_s
      end
    end

    nil
  end

  def record(action)
    obj = JSON.parse(BugSerializer.new(self).to_json)
    obj['bug'] = obj['bug'].except('notes', 'attachments', 'tasks', 'exploits')
    obj['bug']['user'] = obj['bug']['user_id']
    record = { resource: 'bug',
               action: action,
               id: self.id,
               obj: obj.except('notes', 'attachments', 'rules', 'references', 'tasks', 'exploits') }
    PublishWebsocket.push_changes(record)
  end

  def get_state(status, resolution, user)
    bug_state = 'OPEN'
    if status == 'REOPENED'
      bug_state = status
    elsif STATES_RESOLVED.include? status
      bug_state = resolution
    else
      if user != ('vrt-incoming@sourcefire.com' || nil)
        bug_state = 'ASSIGNED'
      else
        bug_state = 'NEW'
      end
    end
    bug_state
  end

  def toggle_liberty
    if liberty_clear?
      update(liberty: LIBERTY_EMBARGO)
    else
      update(liberty: LIBERTY_CLEAR)
    end
    self.liberty
  end

  #this is an escalation bug method and should be moved
  def acknowledge_bug(comment, xmlrpc)
    options = {}
    options[:comment] = comment.blank? ? "No comment given" : comment
    options[:id] = id
    Note.process_note(options, xmlrpc)
    update(acknowledged: true)
    self.acknowledged

  end

  def update_bug(xmlrpc, options)
    unless xmlrpc.nil?
      # the bugzilla session is where we authenticate
      changed_bug = Bugzilla::Bug.new(xmlrpc).update(options.to_h)
    end
    changed_bug
  end

  def self.bugs_with_search(query_params, product = nil)
    case
      when query_params[:bugzilla_max].present?
        nil
      when query_params[:summary].present? || query_params[:whiteboard].present? || query_params[:giblets].present? || query_params[:snippet]
        summary_param = ""
        whiteboard_param = ""
        snippet_param = ""
        giblets = []

        if query_params[:summary].present?
          summary_param = query_params.delete(:summary)
        end

        if query_params[:whiteboard].present?
          whiteboard_param = query_params.delete(:whiteboard)
        end

        if query_params[:snippet].present?
          snippet_param = query_params.delete(:snippet)
        end

        if query_params[:giblets].present?
          giblets = query_params.delete(:giblets)
          gibs = Giblet.where(:id => giblets)
          join_types = gibs.all.map {|g| g.gib_type.downcase.pluralize.to_sym}.uniq
          gibs_by_type = {}
          join_types.each do |join_type|
            gibs_by_type[join_type] = []
          end
          gibs.each do |gib|
            gibs_by_type[gib.gib_type.downcase.pluralize.to_sym] << gib
          end

        end
        if product == "escalations"
          query = Bug.where(:product => "escalations")
        else
          query = Bug
        end
        query_hash = {}

        query_hash['param_results'] = query.where(query_params)

        if summary_param.present?
          query_hash['summary_param_results'] = query_hash['param_results'].where('summary LIKE ?', "%#{summary_param}%")
        end

        if whiteboard_param.present?
          query_hash['whiteboard_param_results'] = query_hash['param_results'].where('whiteboard LIKE ?', "%#{whiteboard_param}%")
        end

        if giblets.present?
          
          gibs_by_type.each do |key, value|
            if value.size > 0
              ids = value.map{|g| g.gib.id}
              case key
                when :tags
                  query_hash['gib_tag_results'] = query_hash['param_results'].joins(:tags)
                                                                             .where("bugs_tags.tag_id" => ids)
                                                                             .group(:bug_id).having('count(bug_id) = ?', ids.count)
                when :whiteboards
                  query_hash['gib_whiteboard_results'] = query_hash['param_results'].joins(:whiteboards)
                                                                                    .where("bugs_whiteboards.whiteboard_id" => ids)
                                                                                    .group(:bug_id).having('count(bug_id) = ?', ids.count)
                when :references
                  query_hash['gib_reference_results'] = query_hash['param_results'].joins(:references)
                                                                                   .where("bug_reference_rule_links.reference_id" => ids)
                                                                                   .group(:link_id).having('count(link_id) = ?', ids.count)
              end
            end
          end
        end

        if snippet_param.present?
          notes = Note.where(:bug_id => query_hash['param_results'].map{|b| b.id})
          notes = notes.where("comment like '%#{snippet_param}%'")
          bug_ids = notes.map {|b| b.bug_id}
          query_hash['snippet_param_results'] = query_hash['param_results'].where(:id => bug_ids)
        end

        if query_params.empty?
          query_hash.delete('param_results')
        end

        #combine all the queries together
        final_query = query_hash.values

        #find intersection of results
        intersection = final_query.inject(:&)

        bug_ids = intersection.pluck(:id)

        query = Bug.where(id: bug_ids)

      else
        if product == "escalations"
          Bug.by_escalations.where(query_params)
        else
          Bug.where(query_params)
        end

    end
  end

  def self.query(current_user, named_query, search_options, product = nil)

    case named_query
      when NilClass
        nil
      when "all-bugs"
        if product == "escalations"
          @bugs = Bug.by_escalations
        else
          @bugs = Bug.all
        end
      when "open-bugs"
        if product == "escalations"
          @bugs = Bug.open_bugs.by_escalations
        else
          @bugs = Bug.open_bugs
        end
      when "pending-bugs"
        if product == "escalations"
          @bugs = Bug.pending.by_escalations
        else
          @bugs = Bug.pending
        end
      when 'fixed-bugs'
        if product == "escalations"
          Bug.closed.by_escalations
        else
          Bug.closed
        end
      when "my-bugs"
        if product == "escalations"
          current_user.bugs.by_escalations
        else
          current_user.bugs
        end
      when "my-open-bugs"
        if product == "escalations"
          current_user.bugs.open_bugs.by_escalations
        else
          current_user.bugs.open_bugs
        end
      when "team-bugs"
        if current_user.is_on_team?
          if current_user.has_role?('manager')
            if product == "escalations"
              Bug.by_escalations.where(user_id: [current_user.id] + current_user.siblings.map{ |cw| cw.id } + current_user.children.map{ |cw| cw.id }) || []
            else
              Bug.where(user_id: [current_user.id] + current_user.siblings.map{ |cw| cw.id } + current_user.children.map{ |cw| cw.id }) || []
            end
          else
            if product == "escalations"
              Bug.by_escalations.where(user_id: current_user.siblings.map{ |cw| cw.id } << current_user.id) || []
            else
              Bug.where(user_id: current_user.siblings.map{ |cw| cw.id } << current_user.id) || []
            end
          end
        else
          if product == "escalations"
            current_user.bugs.by_escalations
          else
            current_user.bugs
          end
        end
      when "advance-search"
        if product == "escalations"
          Bug.bugs_with_search(search_options, product) || Bug.by_escalations
        else
          Bug.bugs_with_search(search_options) || Bug.all
        end
      else
        nil
    end
  end

  def clear_rule_tested
    bugs_rules.update_all(tested:false)
  end

  def rule_in_summary(rule)
    summary_rule = bugs_rules.where(rule_id: rule.id)
    summary_rule.update(in_summary: true)
  end

  def update_attachments(xmlrpc)
    fields = ['file_name', 'id', 'last_change_time', 'is_obsolete', 'size']

    # Now fetch the bug attachments and create them if needed
    xmlrpc.attachments(ids: [bugzilla_id], include_fields: fields)['bugs'][bugzilla_id.to_s].each do |attachment|
      next if File.extname(attachment['file_name'].downcase) != ".pcap"
      attach = Attachment.find_by_bugzilla_attachment_id(attachment['id'])

      # We need to remove any obsoleted attachments
      if attachment['is_obsolete'] == 1
        if attach && attach.bug == self
          attachments.delete(attach)
        end
      else
        if attach

          # Make sure to update file name and size as well
          attach.filename = attachment['file_name']
          attach.file_size = attachment['size']
          attach.save

          if attach.bug != self
            self.attachments << attach
            clear_rule_tested
          end
        else
          begin
            attachments << Attachment.create(
              filename: attachment['file_name'],
              bugzilla_attachment_id: attachment['id'],
              file_size: attachment['size']
            )
          rescue ActiveRecord::RecordNotUnique => e
            # Ignore duplicate attempts
          end
        end
      end
    end
  end

  def self.get_updated_time(bug, state, update_time)
    last_changed_time={}
    case state #if the state is the same as the bug state then dont do anything.
      when 'ASSIGNED'
        last_changed_time[:assigned_at] = update_time
      when 'PENDING'
        last_changed_time[:pending_at] = update_time
        if bug.state == 'REOPENED'
          last_changed_time[:rework_time] = bug.reopened_at? ? ((last_changed_time[:pending_at] - bug.reopened_at) / 86_400).ceil : nil
        else
          last_changed_time[:work_time] = bug.assigned_at? ? ((last_changed_time[:pending_at] - bug.assigned_at) / 86_400).ceil : nil
        end
      when 'FIXED', 'WONTFIX', 'INVALID', 'DUPLICATE', 'LATER', 'COMPLETED'
        last_changed_time[:resolved_at] = update_time
        last_changed_time[:review_time] = bug.pending_at? ? ((last_changed_time[:resolved_at] - bug.pending_at) / 86_400).ceil : nil
      when 'REOPENED'
        last_changed_time[:reopened_at] = update_time
      when 'OPEN'
        last_changed_time[:reopened_at] = update_time
    end

    #return state params hash
    last_changed_time
  end

  def self.get_new_bug_state(bug, state, state_comment, editor_email)
    updated_state = state
    updated_state = 'NEW' if editor_email == 'vrt-incoming@sourcefire.com' && bug.resolution == 'OPEN' && state == 'NEW'
    updated_state = 'ASSIGNED' unless (editor_email == 'vrt-incoming@sourcefire.com') || (%w(RESOLVED REOPENED).include? bug.status) || ['PENDING','FIXED', 'WONTFIX', 'LATER', 'INVALID', 'DUPLICATE', 'COMPLETED'].include?(state)
    updated_state = nil if updated_state == bug.state
    state_params = {}

    case updated_state #if the state is the same as the bug state then dont do anything.
    when 'NEW'
      state_params[:status] = updated_state
      state_params[:resolution] = 'OPEN'
      state_params[:comment] = { comment: "#{state_comment} \nThis bug has been set back to NEW. #{bug.user.email} is no longer assigned to this bug." }
    when 'ASSIGNED'
      state_params[:status] = updated_state
      state_params[:resolution] = 'OPEN'
      state_params[:comment] = { comment: "#{state_comment} \nThis bug is now ASSIGNED to #{editor_email}." }
    when 'PENDING'
      state_params[:status] = 'RESOLVED'
      state_params[:resolution] = updated_state
      state_params[:comment] = { comment: "#{state_comment} \nThis bug is now RESOLVED - #{updated_state}." }
    when 'FIXED', 'WONTFIX', 'INVALID', 'DUPLICATE', 'LATER', 'COMPLETED'
      state_params[:status] = 'RESOLVED'
      state_params[:resolution] = updated_state
      state_params[:comment] = { comment: "#{state_comment} \nThis bug is now RESOLVED - #{updated_state}." }
    when 'REOPENED'
      state_params[:status] = updated_state
      state_params[:resolution] = 'OPEN'
      state_params[:comment] = { comment: "#{state_comment} \nThis bug is now #{updated_state}." }
      state_params[:qa_contact] = User.where(email:"vrt-qa@vrt.sourcefire.com").first
    when 'OPEN'
      state_params[:status] = updated_state
      state_params[:resolution] = 'OPEN'
      state_params[:comment] = { comment: "#{state_comment} \nThis bug is now #{updated_state}." }
    end

    #return state params hash
    state_params
  end

  def self.get_new_escalation_state(state)
    state_params = {}

    case state
      when 'NEW'
        state_params[:status] = state
        state_params[:resolution] = 'OPEN'

      when 'ASSIGNED'
        state_params[:status] = state
        state_params[:resolution] = 'OPEN'

      when 'PENDING'
        state_params[:status] = 'RESOLVED'
        state_params[:resolution] = state

      when 'FIXED', 'WONTFIX', 'INVALID', 'DUPLICATE', 'LATER'
        state_params[:status] = 'RESOLVED'
        state_params[:resolution] = state

      when 'REOPENED'
        state_params[:status] = state
        state_params[:resolution] = 'OPEN'
        state_params[:comment] = { comment: "#{state_comment} \nThis bug is now #{state}." }

      when 'OPEN'
        state_params[:status] = state
        state_params[:resolution] = 'OPEN'

    end


    state_params

  end

  def priority_sort
    if priority.nil?
      priority = 'Unspecified'
    else
      priority
    end
  end

  def rules_parsed?
    rules.each do |rule|
      next unless 1 == rule.gid
      next if Rule::EDIT_STATUS_SYNCHED == rule.edit_status

      return false unless rule.parsed?
    end
    true
  end

  def resolve_errors
    unless @resolve_errors
      @resolve_errors = []

      @resolve_errors << "Rules must be valid." unless rules_parsed?

    end
    @resolve_errors
  end

  def can_resolve?
    resolve_errors.empty?
  end

  def allow_state_change?
    if !user.present? || !committer.present?
      return false
    end
    true
  end

  def parse_summary
    parsed_summary = {}
    parsed_summary[:sids] = summary_sids
    parsed_summary[:tags] = summary_tags
    parsed_summary[:refs] = summary_references
    parsed_summary
  end

  def summary_tags
    summary_tags = summary_tag_array.map { |s| s.delete '[]' }
    if summary_tags
      create_tags_from_summary(summary_tags)
      summary_tags.map { |tag| Tag.find_by_name(tag) }
    else
      []
    end
  end

  # Scans a string for sid expressions.
  # A sid expression can be a list of sids, or a range denoted with a dash.
  # @param [String, #read] rest The rest of the string after the [SID] keyword
  # @return [Array[Integer]] the sids
  def scan_sids(rest)
    sids = []
    enum = rest.split(/\s*[,\s]\s*/).each_entry
    curr = enum.next
    while curr.empty? || (/\A\s*(?<sidexp>[\d,\-]+)\z/ =~ curr)
      unless curr.empty?
        if /(?<lo>\d+)-(?<hi>\d+)/ =~ sidexp
          unless (0 >= lo.to_i) || (0 >= hi.to_i)
            sids += (lo.to_i..hi.to_i).to_a
          end
        else
          sids << sidexp.to_i unless 0 >= sidexp.to_i
        end
      end

      curr = enum.next
    end
    sids
  rescue StopIteration
    sids
  end

  # Scans summary for sid expressions.
  # The sids must follow a [SID] substring.
  # A sid expression can be a list of sids, or a range denoted with a dash.
  # @return [Array[Integer]] the sids
  def summary_sids
    sids = []
    if summary.present?
      index = summary.index("[SID]")
      if index
        sids = scan_sids(summary[(index + 5)..-1])
      end
    end
    sids
  end

  # Takes an array of sids and adds their rules to the bug if not already on the bug.
  def load_rules_from_sids(sids, component = "Snort Rules", import_type = "import")
    sids.each do |sid|
      gid = component == "SO Rules" ? 3 : 1
      rule = Rule.find_or_load(sid)
      if rule
        @import_report[:new_rules] << rule.sid_colon_format unless self.rules.include? rule
        if import_type != "status"
          rules << rule unless self.rules.include? rule
          rule_in_summary(rule)
        end
      end
    end
  end

  def summary_references
    references = []
    ReferenceType.where.not(bugzilla_format: nil).each do |ref_type|
      summary_without_sids_or_tags.scan(/#{ref_type.bugzilla_format}/i).each do |match|
        ref = Reference.where(reference_type_id: ref_type.id, reference_data: match[0]).first_or_create
        references << ref
      end
    end
    references.uniq
  end

  def load_references(summary_references, old_refs = nil)

    if old_refs.present?
      old_refs.each do |old_ref|
        if references.include? (old_ref)
          references.delete(old_ref)
        end
      end
    end

    summary_references.each do |ref|
      references << ref unless references.map {|r| r.reference_data}.include? ref.reference_data
      Exploit.find_exploits(ref)
    end


  end

  def tag_array
    # array of tags for comparison
    tags.map { |t| "[#{t.name}]" }
  end

  def summary_tag_array
    # array of tags in summary for comparison
    summary_without_sids.scan(/\[.*?\]/)
  end

  def compose_summary
    if tag_array.try(:sort) != summary_tag_array.try(:sort)
      #extract summary_tag_string and replace with tag_string
      summary_string = "#{summary}"
      summary_tag_array.each{|st| summary_string.slice! st } unless summary_tag_array.nil?
      tag_array.reverse.each{|ta| summary_string.prepend(ta) }
      self.update(summary: summary_string)
    end
  end

  def update_summary(summary_given, old_refs = nil)
    update!(summary: summary_given)

    parsed = parse_summary
    load_tags_from_summary(parsed[:tags] )
    load_rules_from_sids(summary_sids)
    load_refs_from_summary(summary_references)
    compose_summary
    load_references(summary_references, old_refs)

  end

  def bugzilla_synch_needed?
    notes.empty?
  end

  def resolution_time
    if resolved_at.present?
      ((resolved_at - created_at) / 86_400).ceil
    else
      0
    end
  end

  def metrics_available?
    work_time || rework_time || review_time || resolution_time != 0
  end

  def check_permission(current_user)
    User.class_levels[current_user.class_level] >= Bug.classifications[self.classification]
  end

  def create_tags_from_summary(summary_tags)
    sum_tags=[]
    summary_tags.each do |tag|
      found_tag = Tag.find_by_name(tag)
      unless found_tag
        found_tag = Tag.create(name: tag)
      end
      sum_tags << found_tag
    end
    sum_tags
  end

  def add_attachment(xmlrpc, file)
    Bugzilla::Bug.new(xmlrpc).attach_file(bugzilla_id, file)
  end

  ####methods for bug importing######

  def load_whiteboard_values
    if self.whiteboard.present?
      tokens = self.whiteboard.split(" ")
      tokens.each do |token|
        unless token.blank?
          w_board = Whiteboard.where(:name => token).first
          if w_board.blank?
            w_board = Whiteboard.create(:name => token)
          end

          unless self.whiteboards.include?(w_board)
            self.whiteboards << w_board
          end

          if giblets.select {|giblet| giblet.gib == w_board}.blank?
            new_gib = Giblet.create(:bug_id => self.id, :gib_type => "Whiteboard", :gib_id => w_board.id)
            new_gib.name = new_gib.display_name
            new_gib.save
          end
        end

      end
    end
  end

  def load_tags_from_summary(tags, import_type='import')
    tags.each do |tag|
      @import_report[:new_tags] << tag.name unless self.tags.include?(tag) if defined? @import_report
      if import_type != "status"
        unless self.tags.include?(tag)
          self.tags << tag

        end

        if giblets.select {|giblet| giblet.gib == tag}.blank?
          new_gib = Giblet.create(:bug_id => self.id, :gib_type => "Tag", :gib_id => tag.id)
          new_gib.name = new_gib.display_name
          new_gib.save
        end

      end
    end
  end

  def load_refs_from_summary(refs, import_type='import_type')
    refs.each do |ref|
      @import_report[:new_refs] << ref.reference_data unless self.references.map {|r| r.reference_data}.include? ref.reference_data if defined? @import_report
      if import_type != "status"
        unless self.references.map {|r| r.reference_data}.include? ref.reference_data
          self.references << ref

        end

        if giblets.select {|giblet| giblet.gib == ref}.blank?
          if ref.reference_type.name != "url"
            new_gib = Giblet.create(:bug_id => self.id, :gib_type => "Reference", :gib_id => ref.id)
            new_gib.name = new_gib.display_name
            new_gib.save
          else
            if ref.reference_data.include?("microsoft.com")
              msb_val = ref.reference_data.split('/').last.split('.').first.upcase
              ref_type = ReferenceType.where(:name => 'msb').first
              alt_ref = Reference.find_or_create_by(:reference_type_id => ref_type.id, :reference_data => msb_val)
              references << alt_ref unless references.include?(alt_ref)
              new_gib = Giblet.create(:bug_id => self.id, :gib_type => "Reference", :gib_id => alt_ref.id)
              new_gib.name = new_gib.display_name
              new_gib.save
            end
          end
        end
      end
      unless import_type == 'shallow'
        Exploit.find_exploits(ref)
      end
    end
  end

  def load_giblets_from_refs
    references.each do |ref|
      if giblets.select {|giblet| giblet.gib == ref}.blank?
        if ref.reference_type.name != "url"
          new_gib = Giblet.create(:bug_id => self.id, :gib_type => "Reference", :gib_id => ref.id)
          new_gib.name = new_gib.display_name
          new_gib.save
        else
          if ref.reference_data.include?("microsoft.com")
            msb_val = ref.reference_data.split('/').last.split('.').first.upcase
            ref_type = ReferenceType.where(:name => 'msb').first
            alt_ref = Reference.find_or_create_by(:reference_type_id => ref_type.id, :reference_data => msb_val)
            references << alt_ref unless references.include?(alt_ref)
            new_gib = Giblet.create(:bug_id => self.id, :gib_type => "Reference", :gib_id => new_ref.id)
            new_gib.name = new_gib.display_name
            new_gib.save
          end
        end
      end
    end
  end

  ####end method group###############

  # @param [Bugzilla::Bug] bugzilla_bug_proxy
  # @param [Hash] new_bugs_hash
  def self.synch_history(bugzilla_bug_proxy, new_bugs_hash)
    unless new_bugs_hash.empty?
      new_bugs_hash['bugs'].each do |item|
        bug_id = item['id']
        begin
          new_comments = bugzilla_bug_proxy.comments(ids: [bug_id])
        rescue RuntimeError => e
          new_comments = []
          Note.create(author: 'AC Admin',
                      comment: "Sorry! The Bugzilla API can't even these comments.\nERROR: #{e}.",
                      note_type: 'error',
                      bug_id: bug_id)
        end
        bug = Bug.where(bugzilla_id: bug_id).first
        unless new_comments.empty?

          ActiveRecord::Base.transaction do
            new_bug = bug.notes.published.blank?
            bug_has_notes = bug.has_notes?
            new_comments['bugs'].each do |comment|
              bug_id = comment[0].to_i
              comment[1]['comments'].each do |c|
                next if Note.where(id: c['id']).first.present? #we already have this one
                if c['text'].downcase.strip.start_with?('commit')
                  note_type = 'committer'
                elsif c['text'].start_with?('Created attachment')
                  note_type = 'attachment'
                else
                  note_type = 'research'
                end
                comment = c['text'].strip
                creation_time = c['creation_time'].to_time
                note = Note.where(id: c['id']).first
                if note.present?
                  note.update_attributes({
                    author:     c['creator'],
		                comment:    comment,
		                bug_id:     bug_id,
                    note_type:  note_type,
                    notes_bugzilla_id: c['id'],
                    created_at: creation_time
	                })
                else
                  Note.create({
	                  id:         c['id'],
                    author:     c['creator'],
                    comment:    comment,
                    bug_id:     bug_id,
                    note_type:  note_type,
                    created_at: creation_time,
                    notes_bugzilla_id: c['id']
                  })
                end
              end
            end
            if new_bug
              last_committer_note = bug.notes.last_committer_note.first
              if last_committer_note.present?

                committer_note_text_area = ""
                if last_committer_note
                  committer_note_text_area = Note.parse_from_note(last_committer_note.comment,"Committer Notes:") + "\n"
                end
                new_note = Note.where(notes_bugzilla_id: nil,bug_id: bug_id).committer_note.first_or_create
                new_note.note_type = 'committer'
                new_note.comment = new_note.comment.nil? ? committer_note_text_area : committer_note_text_area + "\n" + new_note.comment
                new_note.author = last_committer_note.author
                new_note.created_at = Time.now.to_time
                new_note.save

              end
            end
            latest_research = bug.notes.where("note_type=? and comment like 'Research Notes:%'", "research").reverse_chron.first
            if latest_research.present? && !(bug_has_notes)
              new_draft = Note.parse_from_note(latest_research.comment, "Research Notes:", false)
              bug.research_notes = new_draft
            end
          end
        end
      end
    end
  end

  def self.synch_attachments(xmlrpc, new_bugs, current_user)
    unless new_bugs.empty?
      new_bugs['bugs'].each do |item|
        bug_id = item['id']
        new_attachments = xmlrpc.attachments(ids: [bug_id])
        bug = Bug.where(bugzilla_id: bug_id).first
        unless new_attachments.empty?
          new_attachments['bugs'][bug_id.to_s].each do |attachment|
            local_attachment = Attachment.where(bugzilla_attachment_id: attachment['id']).first
            if local_attachment.present?
              if attachment['is_obsolete'] == 1
                local_attachment.is_obsolete = true
                local_attachment.save
              end

            else
              local_attachment = Attachment.create do |new_attach_record|
                new_attach_record.id = attachment['id']
                new_attach_record.size = attachment['size']
                new_attach_record.bugzilla_attachment_id = attachment['id'] #this is the id comming from bugzilla
                new_attach_record.file_name = attachment['file_name']
                new_attach_record.summary = attachment['summary']
                new_attach_record.content_type = attachment['content_type']
                new_attach_record.direct_upload_url = "https://#{Rails.configuration.bugzilla_host}/attachment.cgi?id=" + new_attach_record.id = attachment['id'].to_s
                new_attach_record.creator = attachment['attacher']
                new_attach_record.is_private = attachment['is_private']
                new_attach_record.is_obsolete = attachment['is_obsolete']
                new_attach_record.minor_update = false
                new_attach_record.created_at = attachment['creation_time'].to_time
              end
            end
            bug.attachments << local_attachment unless bug.attachments.pluck(:bugzilla_attachment_id).include?(local_attachment.bugzilla_attachment_id)
          end
        end
        #we need to test these new attachments
        options = {
            :bug              => Bug.where(id: bug_id).first,
            :task_type        => Task::TASK_TYPE_PCAP_TEST,
            :attachment_array => bug.attachments.pcap.map{|a| a.id},
        }
        begin
          if options[:attachment_array].any?
            new_task = Task.create(
                :bug  => options[:bug],
                :task_type     => options[:task_type],
                :user => current_user
            )
            TestAttachment.new(new_task, xmlrpc_token, options[:attachment_array]).send_work_msg
          end
        rescue Exception => e
          #handle timeouts accordingly
          Rails.logger.info("Rails encountered an error but is powering through it. #{e.message}")
        end
      end
    end
  end

  ####PROCESSING THE WORKFLOW OF A BUG UPDATE#########

  def self.publish_research_notes(xmlrpc, current_user, bug)

    notes_to_append = "#{bug.research_notes}\n\n--------------------------------------------------\n"

    ###NEW AND/OR UPDATED RULES####

    if bug.rules.any?
      updated_rules = []
      new_rules = []
      bug.rules.each do |rule|
        if rule.state == Rule::NEW_STATE
          new_rules << rule
        end
        if rule.state == Rule::UPDATED_STATE
          updated_rules << rule
        end
      end

      if new_rules.any?
        new_rules_text = "\nNew Rules:\n--------------------------------------------------\n"
        new_rules.each do |rule|
          new_rules_text += "     #{rule.rule_content}\n"
        end
        new_rules_text += "--------------------------------------------------\n"
      end

      if updated_rules.any?
        updated_rules_text = "\nUpdated Rules:\n--------------------------------------------------\n"
        updated_rules.each do |rule|
          updated_rules_text += "     #{rule.rule_content}\n"
        end
        updated_rules_text += "--------------------------------------------------\n"
      end

    end

    if new_rules_text.present?
      notes_to_append += new_rules_text
    end
    if updated_rules_text.present?
      notes_to_append += updated_rules_text
    end

    ####################

    ###append alerts#####

    alert_base = "\nAlerts:\n--------------------------------------------------\n"
    pcap_attachments = []
    bug.attachments.where(is_obsolete: false).map do |att|
      if File.extname(att.file_name.downcase) == ".pcap"
        pcap_attachments << att
      end
    end

    if pcap_attachments.any?
      alerts_message = ""
      did_alert = false
      pcap_attachments.each do |attachment|
        if attachment.pcap_alerts.any?
          alerts_message += "     #{attachment.file_name}:\n"
          attachment.pcap_alerts.joins(:rule).where.not(rules: {sid: nil}).order('rules.gid, rules.sid').each do |alert|
            p_rule = alert.rule
            alerts_message += "          #{p_rule.gid}:#{p_rule.sid}:#{p_rule.rev} - #{p_rule.message}\n"
            did_alert = true
          end
        end
      end
      if did_alert
        final_alert_message = alert_base
        final_alert_message += alerts_message
        final_alert_message += "\n--------------------------------------------------\n"
      end

    end

    if final_alert_message.present?
      notes_to_append += final_alert_message
    end



    bug_related_base = "\nBug Related Rules:\n--------------------------------------------------\n"

    if bug.rules.any?
      related_bugs_message = bug_related_base
      bug.rules.each do |rule|
        related_bugs_message += "     #{rule.gid}:#{rule.sid}:#{rule.rev} #{rule.message}\n"
      end
      related_bugs_message += "--------------------------------------------------\n"
    end

    if related_bugs_message.present?
      notes_to_append += related_bugs_message
    end

    options = {}
    options[:id] = bug.id
    options[:comment] = notes_to_append
    options[:note_type] = "research"
    options[:author] = current_user.email

    Note.process_note(options, xmlrpc)

  end

  def resolve_blocked_bugs(bug_stub, current_user:, new_escalation_message:, new_escalation_state:)
    snort_blocked_bugs.each do |blocked_bug|
      options = {
          :id => blocked_bug.bugzilla_id,
          :comment => new_escalation_message,
      }
      new_note = bug_stub.add_comment(options)
      Note.create(
          :id => new_note['id'],
          :comment => new_escalation_message,
          :author => current_user.email,
          :note_type => 'research',
          :bug_id => blocked_bug.id,
          :notes_bugzilla_id => new_note['id']
      )

      updated_bug_state = Bug.get_new_escalation_state(new_escalation_state)
      blocked_bug.state = new_escalation_state
      blocked_bug.status = updated_bug_state[:status]
      blocked_bug.resolution = updated_bug_state[:resolution]
      blocked_bug.save

      updated_bug_options =
          Bug.get_new_bug_state(blocked_bug, new_escalation_state, new_escalation_message, current_user.email)
      updated_bug_options[:ids] = blocked_bug.id
      bug_stub.update(updated_bug_options.to_h)

    end
    BugBlocker.where(snort_blocker_bug_id: self.id).delete_all
  end

  # TODO Why is this a Bug class method when it takes a required bug object as an argument?
  # TODO Do we really have a method spanning 200 lines without an opportunity to break it into sub-methods?
  def self.process_bug_update(current_user, xmlrpc, bug, permitted_params, assignee:, committer:, new_escalation_message: nil, new_escalation_state: nil)

    initial_bug_summary_info = bug.parse_summary
    initial_refs_from_summary = initial_bug_summary_info[:refs]
    initial_state = bug.state

    bug.initialize_report

    is_becoming_resolved = ("PENDING" == permitted_params[:bug][:state]) && ("PENDING" != bug.state)

    if is_becoming_resolved
      bug.resolve_blocked_bugs(xmlrpc,
                               current_user: current_user,
                               new_escalation_message: new_escalation_message,
                               new_escalation_state: new_escalation_state)
      publish_research_notes(xmlrpc, current_user, bug)
    end



    #add a comment to the existing committer note. from issue 981
    if permitted_params[:bug][:state_comment]
      c_note = bug.current_committer_note
      if c_note
        c_note.comment << "\n\n#{permitted_params[:bug][:state_comment]}"
        c_note.save
      else
        bug.notes << Note.create(
            comment: permitted_params[:bug][:state_comment],
            author: "#{bug.committer&.email || bug.user&.email}",
            note_type: "committer",
            bug_id: bug.bugzilla_id
        )
      end
    end

    bug.summary = permitted_params[:bug][:summary]
    new_summary = bug.parse_summary
    bug.reload


    # update the tags
    bug.tags.delete_all if bug.tags.exists?

    if new_summary[:tags]
      new_summary[:tags].each do |tag|
        new_tag = Tag.find_or_create_by(name: tag.name)
        bug.tags << new_tag
      end
    end


    updated_bug_state = Bug.get_new_bug_state(bug, permitted_params[:bug][:state], permitted_params[:bug][:state_comment], assignee.email)

    if initial_state != "REOPENED" && permitted_params[:bug][:state] == "REOPENED"
      updated_bug_state[:qa_contact] = User.where(email: "vrt-qa@sourcefire.com").first
      bug.snort_escalation_bugs.each do |blocked_bug|
        bug.snort_blocked_bugs << blocked_bug
      end
    end


    options = {
        ids: permitted_params[:id],
        assigned_to: assignee.email,
        status: updated_bug_state[:status],
        resolution: updated_bug_state[:resolution],
        comment: updated_bug_state[:comment],
        qa_contact: updated_bug_state[:qa_contact]&.email || committer&.email
    }

    # update the summary
    # (do this first so we can compose the summary properly to send to bugzilla)

    bug.update_summary(permitted_params[:bug][:summary], initial_refs_from_summary)

    options[:ids] = permitted_params[:id]
    options[:product] = permitted_params[:bug][:product]
    options[:component] = permitted_params[:bug][:component]
    options[:summary] = bug.summary
    options[:version] = permitted_params[:bug][:version]
    options[:state] = permitted_params[:bug][:state]
    options[:creator] = permitted_params[:bug][:creator]
    options[:opsys] = permitted_params[:bug][:opsys]
    options[:platform] = permitted_params[:bug][:platform]
    options[:priority] = permitted_params[:bug][:priority]
    options[:severity] = permitted_params[:bug][:severity]
    options[:classification] = permitted_params[:bug][:classification]
    options[:whiteboard] = permitted_params[:bug][:whiteboard]


    # update buzilla (if needed)
    options.reject! { |k, v| v.nil? } if options

    updated_bug = xmlrpc.update(options.to_h) unless options.blank?

    last_changed_time = updated_bug["bugs"][0]["last_change_time"].to_time

    updated_bug_time = get_updated_time(bug, permitted_params[:bug][:state], last_changed_time)
    update_params = {
        user: assignee,
        state: updated_bug_state[:state],
        status: updated_bug_state[:status],
        summary: updated_bug_state[:summary],
        resolution: updated_bug_state[:resolution],
        assigned_at: updated_bug_time[:assigned_at],
        pending_at: updated_bug_time[:pending_at],
        resolved_at: updated_bug_time[:resolved_at],
        reopened_at: updated_bug_time[:reopened_at],
        work_time: updated_bug_state[:work_time],
        rework_time: updated_bug_state[:rework_time],
        review_time: updated_bug_state[:review_time],
        committer: updated_bug_state[:qa_contact] || committer
    }

    #not sure if this was intended but i noticed if there is a new_research_note or new_committer_note it blows away all
    #update_params and fills it with just the resarch/committer note.
    if permitted_params[:bug][:new_research_notes]
      update_params = {
          :research_notes => permitted_params[:bug][:new_research_notes]
      }
    elsif permitted_params[:bug][:new_committer_notes]
      update_params = {
          :committer_notes => permitted_params[:bug][:new_committer_notes]
      }
    end




    update_params[:product] = permitted_params[:bug][:product]
    update_params[:component] = permitted_params[:bug][:component]
    update_params[:summary] = bug.summary
    update_params[:version] = permitted_params[:bug][:version]
    update_params[:state] = permitted_params[:bug][:state]
    update_params[:opsys] = permitted_params[:bug][:opsys]
    update_params[:platform] = permitted_params[:bug][:platform]
    update_params[:priority] = permitted_params[:bug][:priority]
    update_params[:severity] = permitted_params[:bug][:severity]
    update_params[:classification] = permitted_params[:bug][:classification]
    update_params[:whiteboard] = permitted_params[:bug][:whiteboard]
    update_params[:description] = permitted_params[:bug][:description]
    update_params.reject! { |k, v| v.nil? } if update_params

    if update_params[:description].present?
      if bug.description != update_params[:description]

        new_description_message = "Bug Description has changed in Analyst Console, new bug description is as follows: \n"
        new_description_message += update_params[:description]
        options = {
            :id => permitted_params[:id],
            :comment => new_description_message,
        }.reject() { |k, v| v.nil? }
        new_note = xmlrpc.add_comment(options)
        Note.create(
            :id => new_note['id'],
            :comment => new_description_message,
            :author => current_user.email,
            :note_type => 'research',
            :bug_id => permitted_params[:id],
            :notes_bugzilla_id => new_note['id']
        )

      end
    end
    
    # update the database
    update_params.reject! { |k, v| v.nil? }
    Bug.update(permitted_params[:id], update_params)

    bug.reload

    bug.load_whiteboard_values

  end

  ####END BUG UPDATE PROCESS WORKFLOW#############


  ####BUGZILLA IMPORT PROCESS  (tbd: maybe move this into a dedicated process model, it will slim up the Bug class and
  ####                          allow the workflow of the import process to be better broken up while having all relevant
  ####                          code accessible in one spot.)

  ####List of operations:
  ####   1.  Creates and/or updates bug record columns and persists those changes
  ####   2.  Creates and/or updates various User records that are associated with the bug and then associates them with said Bug (createor, assignee, committer)
  ####   3.  Creates and/or updates any attachments that are associated with the Bug and associates them with said Bug.
  ####   4.  Create a task to run tests on those attachments (provided they are pcap files)
  ####   5.  Creates and/or updates any Notes ('comment' in bugzilla) that are associated with the Bug and associate them said Bug.
  ####   6.  If applicable, prepoulate running commit and research notes drafts (found under the Notes tab in a bug view page) from existing comments.  This should only happen in a fresh import or a first time synch from light import
  ####   7.  Load rules from any SIDS parsed from the summary line
  ####   8.  Load any tags parsed from the summary line
  ####   9.  Load any references parsed from the summary line
  ####   10.  Do a final #save to cement all changs and associations
  ####   11.  KEY:  CLEAR ALL TESTED RULES.  User will have to retest to see test results.

  ####   Caveat:
  ####   There is a roaming variable 'import_type' that will run through the same process listed above, but prevent any database persistence
  ####   regarding column changes or relation associations and prevent the tests from being cleared if that import_type has a value of 'status'
  ####   Ideally the possible values of import_type should be ['status', 'import', 'synch'].
  ####   An import_type = 'status' preventing persistence and test clearing should allow for any client side UI functionality
  ####   that checks for bug changes in Bugzilla before executing certain actions (like committing a rule or setting a bug to 'PENDING')

  def append_committer_comment(new_comment)
    if self.committer_notes
      bugzilla_comment = "#{self.committer_notes}\n #{new_comment}"
      update(committer_notes: bugzilla_comment)
    else
      bugzilla_comment = "#{self.notes.last_committer_note.first&.comment}\n #{new_comment}"
    end
    bugzilla_comment
  end

  def self.bugzilla_import(current_user, xmlrpc, xmlrpc_token, new_bugs, progress_bar = nil, import_type = "import")
    import_type = import_type.blank? ? "import" : import_type
    total_bugs = []
    unless new_bugs['bugs'].empty?
      new_bugs['bugs'].each do |item|

        progress_bar.update_attribute("progress", 10) unless progress_bar.blank?

        bug_id = item['id']

        new_attachments = xmlrpc.attachments(ids: [bug_id])

        begin
          new_comments = xmlrpc.comments(ids: [bug_id])
        rescue RuntimeError => e
          new_comments = []
          Note.create(author: 'AC Admin',
                      comment: "Sorry! The Bugzilla API can't even these comments.\nERROR: #{e}.",
                      note_type: 'error',
                      bug_id: bug_id)
        end


        #Update Bug record attributes from bugzilla############
        bug = Bug.where(bugzilla_id: bug_id).first
        case
          when bug
            raise 'Can only process research bugs' unless bug.research_bug?
          when 'Research' != item['product']
            raise 'Can only import research bugs'
          else
            bug = ResearchBug.create(id: bug_id, bugzilla_id: bug_id, product: item['product'])
        end

        bug.initialize_report

        bug.id = bug_id
        bug.summary        = item['summary']
        bug.classification = 'unclassified'
        bug.status     = item['status']
        bug.resolution = item['resolution']

        is_secure = false

        item['groups'].each do |group_item|
          if group_item == "Restriction:VRT Security Bugs"
            is_secure = true
          end
        end

        bug.snort_secure = is_secure

        bug.resolution = 'OPEN' if bug.resolution.empty?

        new_bug_state = bug.get_state(item['status'], item['resolution'], item['assigned_to'])
        state_changed = bug.state != new_bug_state

        bug.state     = new_bug_state if state_changed
        bug.priority  = item['priority']
        bug.component = item['component']
        bug.product   = item['product']
        bug.whiteboard = item['whiteboard']
        bug.created_at = item['creation_time'].to_time
        if state_changed
          last_change_time      = item['last_change_time'].to_time
          if bug.state == 'NEW'
            # do nothing
          elsif bug.state == 'ASSIGNED'
            bug.assigned_at = last_change_time
          elsif bug.state == 'PENDING'
            bug.pending_at = last_change_time
          elsif bug.state == 'REOPENED'
            bug.reopened_at = last_change_time
          else
            bug.resolved_at = last_change_time
          end
        end


        if import_type != "status"
          bug.save
        end
        #end Bug attributes update##################


        #Create/update Bug User relationships

        creator = User.user_by_email(item['creator'])
        bug.creator = creator.id

        new_user = User.user_by_email(item['assigned_to'])
        bug.user = new_user

        new_committer = User.user_by_email(item['qa_contact'])
        bug.committer = new_committer

        if import_type != "status"
          bug.save
        end


        #Create/update Bug Attachments
        unless new_attachments.empty?

          new_attachments['bugs'][bug_id.to_s].each do |attachment|
            local_attachment = Attachment.where(bugzilla_attachment_id: attachment['id']).first
            if local_attachment.present?
              if attachment['is_obsolete'] == 1
                local_attachment.is_obsolete = true
                local_attachment.save
              end
            else
              local_attachment = Attachment.create do |new_attach_record|
                new_attach_record.id = attachment['id']
                new_attach_record.size = attachment['size']
                new_attach_record.bugzilla_attachment_id = attachment['id'] #this is the id comming from bugzilla
                new_attach_record.file_name = attachment['file_name']
                new_attach_record.summary = attachment['summary']
                new_attach_record.content_type = attachment['content_type']
                new_attach_record.direct_upload_url = "https://#{Rails.configuration.bugzilla_host}/attachment.cgi?id=" + new_attach_record.id = attachment['id'].to_s
                new_attach_record.creator = attachment['attacher']
                new_attach_record.is_private = attachment['is_private']
                new_attach_record.is_obsolete = attachment['is_obsolete']
                new_attach_record.minor_update = false
                new_attach_record.created_at = attachment['creation_time'].to_time
              end
            end
            bug.import_report[:new_attachments] << attachment['file_name'] unless bug.attachments.pluck(:bugzilla_attachment_id).include?(local_attachment.bugzilla_attachment_id)
            if import_type != "status"
              bug.attachments << local_attachment unless bug.attachments.pluck(:bugzilla_attachment_id).include?(local_attachment.bugzilla_attachment_id)
            end
          end
        end

        ####we need to test these new attachments #unless its a status check
        if import_type != "status"
          options = {
              :bug              => Bug.where(id: bug_id).first,
              :task_type        => Task::TASK_TYPE_PCAP_TEST,
              :attachment_array => bug.attachments.pcap.map{|a| a.id},
          }

          begin
            if options[:attachment_array].any?
              new_task = Task.create(
                  :bug  => options[:bug],
                  :task_type     => options[:task_type],
                  :user => current_user
              )
              TestAttachment.new(new_task, xmlrpc_token, options[:attachment_array]).send_work_msg
            end
          rescue Exception => e
            #handle timeouts accordingly
            Rails.logger.info("Rails encountered an error but is moving through it. #{e.message}")
          end
        end
        ####end attachment testing###


        bug_has_published_notes = bug.has_published_notes?
        bug_has_notes = bug.has_notes?

        ###build any comments/notes (research and commit messages) from bugzilla####
        ###prepolate running notes (for the Notes tab)
        bug.research_notes ||= Note::TEMPLATE_RESEARCH
        unless new_comments.empty?
          if bug.description.blank?
            if import_type != "status"
              bug.description = new_comments['bugs'].first[1]['comments'].first['text'].strip
              bug.save
            end
          end
          ActiveRecord::Base.transaction do
            #import any new comments from bugzilla
            new_comments['bugs'].each do |comment|
              bug_id = comment[0].to_i
              comment[1]['comments'].each do |c|
                if c['text'].downcase.strip.start_with?('commit')
                  note_type = 'committer'
                elsif c['text'].start_with?('Created attachment')
                  note_type = 'attachment'
                else
                  note_type = 'research'
                end
                comment = c['text'].strip

                creation_time = c['creation_time'].to_time

		            note = Note.where(id: c['id']).first

                if note.present?
                  unless import_type == "status"
                    comment = "bugzilla comment is blank" if comment.blank?
                    note.update_attributes(author: c['creator'],
                                           comment: comment,
                                           bug_id: bug_id,
                                           note_type: note_type,
                                           notes_bugzilla_id: c['id'],
                                           created_at: creation_time)
                  end
                else
                  bug.import_report[:new_notes] += 1
                  unless import_type == "status"
                    comment = "bugzilla comment is blank" if comment.blank?
                    Note.create(id: c['id'],
                                author: c['creator'],
                                comment: comment,
                                bug_id: bug_id,
                                note_type: note_type,
                                created_at: creation_time,
                                notes_bugzilla_id: c['id']                     )
                  end
                end
              end
            end
            #end comment importing####
            ##Running note prepoluation logic here#########
            if import_type != "status"

              #prepopulating committer notes in notes tab

              last_committer_note = bug.notes.last_committer_note.first
              committer_note_text_area = ""
              if last_committer_note.present?
                if last_committer_note
                  committer_note_text_area = Note.parse_from_note(last_committer_note.comment, "Committer Notes:", true) + "\n"
                end
              end
              if bug_has_published_notes
                bug.committer_notes = committer_note_text_area
                bug.save
              else
                new_note = Note.where(notes_bugzilla_id: nil, bug_id: bug_id).committer_note.first_or_create
                new_note.note_type = 'committer'
                new_note.comment = new_note.comment.nil? ? committer_note_text_area : committer_note_text_area + "\n" + new_note.comment
                new_note.author = last_committer_note.nil? ? current_user&.email : last_committer_note.author
                new_note.created_at = Time.now.to_time
                new_note.save
              end


              #prepopulating research notes in notes tab
              latest_research = bug.notes.where("note_type=? and comment like 'Research Notes:%'", "research").reverse_chron.first
              if latest_research.present? && !(bug_has_notes)
                new_draft = Note.parse_from_note(latest_research.comment, "Research Notes:", false)
                bug.research_notes = new_draft
              end
            end

          end
        end
        progress_bar.update_attribute("progress", 20) unless progress_bar.blank?
        bug.load_whiteboard_values
        progress_bar.update_attribute("progress", 30) unless progress_bar.blank?
        parsed = bug.parse_summary
        progress_bar.update_attribute("progress", 50) unless progress_bar.blank?
        bug.load_rules_from_sids(parsed[:sids], bug.component, import_type)
        progress_bar.update_attribute("progress", 60) unless progress_bar.blank?
        bug.load_tags_from_summary(parsed[:tags], import_type)

        progress_bar.update_attribute("progress", 75) unless progress_bar.blank?
        bug.load_refs_from_summary(parsed[:refs], import_type)

        progress_bar.update_attribute("progress", 90) unless progress_bar.blank?

        #save the bug unless the import action is a status check
        if import_type != "status"
          bug.save
        end

        progress_bar.update_attribute("progress", 100) unless progress_bar.blank?

        total_bugs << bug

      end
    else
      if new_bugs.has_key?("faults") && !new_bugs["faults"].empty?
        message = new_bugs["faults"].map {|f| f['faultString']}.join(',')
        raise message
      else
        raise "there was a problem importing from Bugzilla."
      end
    end
    return total_bugs
  end





  def self.bugzilla_import_escalation(current_user, xmlrpc, xmlrpc_token, new_bugs, progress_bar = nil, import_type = "import")
    import_type = import_type.blank? ? "import" : import_type
    total_bugs = []
    if new_bugs['bugs'].empty?
      if new_bugs.has_key?("faults") && !new_bugs["faults"].empty?
        message = new_bugs["faults"].map {|f| f['faultString']}.join(',')
        raise message
      else
        raise "there was a problem importing from Bugzilla."
      end
    else
      new_bugs['bugs'].each do |item|

        progress_bar.update_attribute("progress", 10) unless progress_bar.blank?

        bug_id = item['id']

        new_attachments = xmlrpc.attachments(ids: [bug_id])

        begin
          new_comments = xmlrpc.comments(ids: [bug_id])
        rescue RuntimeError => e
          new_comments = []
          Note.create(author: 'AC Admin',
                      comment: "Sorry! The Bugzilla API can't even these comments.\nERROR: #{e}.",
                      note_type: 'error',
                      bug_id: bug_id)
        end


        #Update Bug record attributes from bugzilla############
        bug = Bug.where(bugzilla_id: bug_id).first
        case
          when bug
            raise 'Can only process escalation bugs' unless bug.escalation_bug?
          when 'Escalations' != item['product']
            raise 'Can only import escalation bugs'
          else
            bug = EscalationBug.create(id: bug_id, bugzilla_id: bug_id, product: item['product'])
        end


        bug.initialize_report

        bug.id = bug_id
        bug.summary        = item['summary']
        bug.classification = 'unclassified'
        bug.status     = item['status']
        bug.resolution = item['resolution']
        bug.resolution = 'OPEN' if bug.resolution.empty?

        new_bug_state = bug.get_state(item['status'], item['resolution'], item['assigned_to'])
        state_changed = bug.state != new_bug_state

        bug.state     = new_bug_state if state_changed
        bug.priority  = item['priority']
        bug.component = item['component']
        bug.product   = item['product']
        bug.whiteboard = item['whiteboard']
        bug.created_at = item['creation_time'].to_time
        if state_changed
          last_change_time      = item['last_change_time'].to_time
          if bug.state == 'NEW'
            # do nothing
          elsif bug.state == 'ASSIGNED'
            bug.assigned_at = last_change_time
          elsif bug.state == 'PENDING'
            bug.pending_at = last_change_time
          elsif bug.state == 'REOPENED'
            bug.reopened_at = last_change_time
          else
            bug.resolved_at = last_change_time
          end
        end


        if import_type != "status"
          bug.save
        end
        #end Bug attributes update##################


        #Create/update Bug User relationships

        creator = User.user_by_email(item['creator'])
        bug.creator = creator.id

        new_user = User.user_by_email(item['assigned_to'])
        bug.user = new_user

        new_committer = User.user_by_email(item['qa_contact'])
        bug.committer = new_committer

        if import_type != "status"
          bug.save
        end


        #Create/update Bug Attachments
        unless new_attachments.empty?

          new_attachments['bugs'][bug_id.to_s].each do |attachment|
            local_attachment = Attachment.where(bugzilla_attachment_id: attachment['id']).first
            if local_attachment.present?
              if attachment['is_obsolete'] == 1
                local_attachment.is_obsolete = true
                local_attachment.save
              end
            else
              local_attachment = Attachment.create do |new_attach_record|
                new_attach_record.id = attachment['id']
                new_attach_record.size = attachment['size']
                new_attach_record.bugzilla_attachment_id = attachment['id'] #this is the id comming from bugzilla
                new_attach_record.file_name = attachment['file_name']
                new_attach_record.summary = attachment['summary']
                new_attach_record.content_type = attachment['content_type']
                new_attach_record.direct_upload_url = "https://#{Rails.configuration.bugzilla_host}/attachment.cgi?id=" + new_attach_record.id = attachment['id'].to_s
                new_attach_record.creator = attachment['attacher']
                new_attach_record.is_private = attachment['is_private']
                new_attach_record.is_obsolete = attachment['is_obsolete']
                new_attach_record.minor_update = false
                new_attach_record.created_at = attachment['creation_time'].to_time
              end
            end
            bug.import_report[:new_attachments] << attachment['file_name'] unless bug.attachments.pluck(:bugzilla_attachment_id).include?(local_attachment.bugzilla_attachment_id)
            if import_type != "status"
              bug.attachments << local_attachment unless bug.attachments.pluck(:bugzilla_attachment_id).include?(local_attachment.bugzilla_attachment_id)
            end
          end
        end


        bug_has_published_notes = bug.has_published_notes?
        bug_has_notes = bug.has_notes?

        ###build any comments/notes (research and commit messages) from bugzilla####
        ###prepolate running notes (for the Notes tab)
        bug.research_notes ||= Note::TEMPLATE_RESEARCH
        unless new_comments.empty?

          ActiveRecord::Base.transaction do
            #import any new comments from bugzilla
            new_comments['bugs'].each do |comment|
              bug_id = comment[0].to_i
              comment[1]['comments'].each do |c|
                if c['text'].downcase.strip.start_with?('commit')
                  note_type = 'committer'
                elsif c['text'].start_with?('Created attachment')
                  note_type = 'attachment'
                else
                  note_type = 'research'
                end
                comment = c['text'].strip

                creation_time = c['creation_time'].to_time

                note = Note.where(id: c['id']).first

                if note.present?
                  unless import_type == "status"
                    comment = "bugzilla comment is blank" if comment.blank?
                    note.update_attributes(author: c['creator'],
                                           comment: comment,
                                           bug_id: bug_id,
                                           note_type: note_type,
                                           notes_bugzilla_id: c['id'],
                                           created_at: creation_time)
                  end
                else
                  bug.import_report[:new_notes] += 1
                  unless import_type == "status"
                    comment = "bugzilla comment is blank" if comment.blank?
                    Note.create(id: c['id'],
                                author: c['creator'],
                                comment: comment,
                                bug_id: bug_id,
                                note_type: note_type,
                                created_at: creation_time,
                                notes_bugzilla_id: c['id']                     )
                  end
                end
              end
            end
            #end comment importing####
            ##Running note prepoluation logic here#########
            if import_type != "status"

              #prepopulating committer notes in notes tab

              last_committer_note = bug.notes.last_committer_note.first
              committer_note_text_area = ""
              if last_committer_note.present?
                if last_committer_note
                  committer_note_text_area = Note.parse_from_note(last_committer_note.comment, "Committer Notes:", true) + "\n"
                end
              end
              if bug_has_published_notes
                bug.committer_notes = committer_note_text_area
                bug.save
              else
                new_note = Note.where(notes_bugzilla_id: nil, bug_id: bug_id).committer_note.first_or_create
                new_note.note_type = 'committer'
                new_note.comment = new_note.comment.nil? ? committer_note_text_area : committer_note_text_area + "\n" + new_note.comment
                new_note.author = last_committer_note.nil? ? current_user&.email : last_committer_note.author
                new_note.created_at = Time.now.to_time
                new_note.save
              end


              #prepopulating research notes in notes tab
              latest_research = bug.notes.where("note_type=? and comment like 'Research Notes:%'", "research").reverse_chron.first
              if latest_research.present? && !(bug_has_notes)
                new_draft = Note.parse_from_note(latest_research.comment, "Research Notes:", false)
                bug.research_notes = new_draft
              end
            end

          end
        end
        progress_bar.update_attribute("progress", 20) unless progress_bar.blank?
        bug.load_whiteboard_values
        progress_bar.update_attribute("progress", 30) unless progress_bar.blank?
        parsed = bug.parse_summary

        progress_bar.update_attribute("progress", 60) unless progress_bar.blank?
        bug.load_tags_from_summary(parsed[:tags], import_type)

        progress_bar.update_attribute("progress", 90) unless progress_bar.blank?

        #save the bug unless the import action is a status check
        if import_type != "status"
          bug.save
        end

        progress_bar.update_attribute("progress", 100) unless progress_bar.blank?

        total_bugs << bug

      end
    end
    return total_bugs
  end


  def self.bugzilla_light_import(new_bugs, xmlrpc, xmlrpc_token, user_email:, current_user: nil)
    unless new_bugs.empty?
      new_bugs['bugs'].each do |item|
        bug_id = item['id']

        bug = Bug.where(bugzilla_id: bug_id).first
        user = nil
        if bug
          user ||= User.where(email: user_email).first
          bug.user = user
          if bug.changed?
            bug.save!
          end
        else
          new_record =
              case item['product']
                when 'Research'
                  ResearchBug.new(bugzilla_id: bug_id)
                when 'Escalations'
                  EscalationBug.new(bugzilla_id: bug_id)
              end

          new_record.id             = bug_id
          new_record.summary        = item['summary']
          new_record.classification = item['classification'].parameterize.downcase.underscore

          new_record.status     = item['status']
          new_record.resolution = item['resolution']
          new_record.resolution = 'OPEN' if new_record.resolution.empty?

          new_bug_state = new_record.get_state(item['status'], item['resolution'], item['assigned_to'])
          state_changed = new_record.state != new_bug_state
          new_record.state     = new_bug_state if state_changed

          new_record.priority  = item['priority']
          new_record.component = item['component']
          new_record.product   = item['product']
          new_record.whiteboard = item['whiteboard']

          new_record.created_at = item['creation_time'].to_time
          if state_changed
            last_change_time      = item['last_change_time'].to_time
            if new_record.state == 'NEW'
              # do nothing
            elsif new_record.state == 'ASSIGNED'
              new_record.assigned_at = last_change_time
            elsif new_record.state == 'PENDING'
              if bug.committer&.cvs_username == "vrtqa"
                new_record.pending_at = last_change_time
              end
            elsif new_record.state == 'REOPENED'
              new_record.reopened_at = last_change_time
            else
              new_record.resolved_at = last_change_time
            end
          end

          creator = User.user_by_email(item['creator'])
          new_record.creator = creator.id

          new_user = User.user_by_email(item['assigned_to'])
          new_record.user = new_user

          new_committer = User.user_by_email(item['qa_contact'])
          new_record.committer = new_committer

          new_record.save!
        end
      end
    end
    true
  end

  def self.get_latest()
    Bug.order('created_at').last
  end

  def self.get_last_import_all()
    # this needs a manifest file to check against should the job fail half way through
    latest_bug_date = Event.where(action: 'import_all').last
    latest_bug_date.nil? ? Time.now - 1.day : latest_bug_date.created_at
  end

  def update_summary_sids(rules, xmlrpc:)
    sids = summary_sids + rules.pluck(:sid)
    compact_string = to_ranges_compact_string(sids)
    self.summary = compact_string.blank? ? "#{summary_without_sids}" : "[SID] #{compact_string} #{summary_without_sids}"
    save!
    # update_bugzilla_attributes(xmlrpc, ids: [bugzilla_id], summary: self.summary )
    self.summary
  end

  def bug_state(xmlrpc, notes=nil, status, resolution)
    deps = open_dependencies(xmlrpc)
    if deps.size > 0
      return { error: "This bug currently has open dependencies: #{deps}" }
    else
      self.state = resolution
      if notes.nil?
        if committer_notes.nil? || committer_notes == ''
          notes = 'Closing bug'
        else
          notes = committer_notes
        end
      end

      committer_note = Note.create(comment: notes,
                                   note_type: 'committer',
                                   author: current_user.email)
      self.notes << committer_note

      options = { ids: [bugzilla_id],
                  status: status,
                  resolution: resolution,
                  comment: { body: notes } }
      update_bugzilla_attributes(xmlrpc, options)
      refresh_summary(xmlrpc)
      bugzilla_summary_sids_replace(xmlrpc, summary_sids)
      options =  { ids: [bugzilla_id],
                   qa_contact: committer.username }
      update_bugzilla_attributes(xmlrpc, options)
      options = { ids: [bugzilla_id],
                  summary: summary.gsub(/\s*\[FP\]\s*/, '') } # Remove FP tags
      update_bugzilla_attributes(xmlrpc, options)
      refresh_summary(xmlrpc)

      true
    end
  end


  def refresh_summary(xmlrpc)
    unless xmlrpc.nil?
      bug = Bugzilla::Bug.new(xmlrpc).get(bugzilla_id)['bugs'].first
      raise Exception.new("Unable to find bug #{record.bugzilla_id}") if bug.nil?
      self.summary = bug['summary']
    end
  end

  def update_bugzilla_attributes(xmlrpc, options)
    unless xmlrpc.nil?
      Bugzilla::Bug.new(xmlrpc).update(options.to_h)
    end
  end

  def bugzilla_summary_sids_add(xmlrpc, sids)
    unless xmlrpc.nil?
      # Make sure to get the latest summary
      refresh_summary(xmlrpc)
      # Now extract the existing sids
      bugzilla_summary_sids_replace(xmlrpc, (summary_sids + sids).flatten.compact)
    end
  end

  def to_ranges(sids)
    sids.uniq.sort.inject([]) do |ranges, sid|
      case
        when ranges.empty?
          ranges << [sid, sid]
        when ranges.last.last + 1 == sid
          ranges.last[1] = sid
        else
          ranges << [sid, sid]
      end
      ranges
    end
  end

  def to_ranges_compact_string(sids)
    to_ranges(sids).map {|range| range.first == range.last ? range.first.to_s : "#{range.first}-#{range.last}"}
        .join(", ")
  end

  def bugzilla_summary_sids_replace(xmlrpc, sids)
    unless xmlrpc.nil?
      sids.delete_if { |sid| sid.zero? }
      unless sids.nil? || sids.empty?
        compact_string = to_ranges_compact_string(sids)
        self.summary = compact_string.blank? ?  "#{summary_without_sids}" : "[SID] #{compact_string} #{summary_without_sids}"
      end
      options = { ids: [bugzilla_id],
                  summary: summary }
      Bugzilla::Bug.new(xmlrpc).update(options.to_h)
    end
  end

  def summary_without_sids
    summary.gsub(/\[SID\]\s*?([\d\s,\-]+)(?:\s)?/, '')
  end

  def summary_without_sids_or_tags
    summary_without_sids.gsub(/(?:(?:\[.*?\])\s*)+/,'')
  end

  def summary_without_sids_or_tags_or_references
    naked_summary = summary_without_sids_or_tags
    summary_references.each do |ref|
      naked_summary.gsub!(/#{ref[0]}\s*/,'')
    end
    naked_summary
  end

  def open_dependencies(xmlrpc)
    raise Exception.new("Bugzilla xmlrpc session must be specified") if xmlrpc.nil?

    return self.get_dependencies(xmlrpc).reject do |i|
      bug = Bugzilla::Bug.new(xmlrpc).get(i)['bugs'].first
      raise Exception.new("Unable to find blocking bug #{i}") if bug.nil?
      (bug['status'] == 'RESOLVED'
      ) ? true : false
    end
  end

  def get_dependencies(xmlrpc)
    raise Exception.new('Bugzilla xmlrpc session must be specified') if xmlrpc.nil?
    bug = Bugzilla::Bug.new(xmlrpc).get(bugzilla_id)['bugs'].first
    raise Exception.new("Unable to find bug #{record.bugzilla_id}") if bug.nil?
    bug['depends_on']
  end

  def has_any_reopenable_bugs
    snort_research_bugs.any? {|bug| ['PENDING', 'FIXED', 'WONTFIX', 'LATER'].include? bug.state}
  end

  def reopenable_bugs
    snort_research_bugs.select {|bug| ['PENDING', 'FIXED', 'WONTFIX', 'LATER'].include? bug.state}
  end

  def self.search(query_str, terms, range)
    Bug.where(summary: query_str) | Bug.where(bugzilla_id: range[:gte]...range[:lte]) | Bug.where(terms.symbolize_keys!)
  end

  def unlink_rule(rule_id)
    rule = Rule.where(id: rule_id).first
    rules.delete(rule) if rule
  end

  def link_alert(attachment_id)
    attachment = Attachment.where(id: attachment_id).first
    attachment.pcap_alerts.each do |alert|
      rule = alert.rule
      rules << rule unless rule.rule_content.blank? || rules.include?(rule)
    end
  end

  def self.link_action(bugzilla_id, sid, gid)
    bug = Bug.where(bugzilla_id: bugzilla_id).first
    rule = Rule.find_or_load(sid, gid)
    if bug && rule
      bug.rules << rule unless bug.rules.include?(rule)
    end
  end

  def self.unlink_action(bug_id, rule_ids)
    bug = Bug.where(id: bug_id).first
    rule_ids.each { |rule_id| bug.unlink_rule(rule_id) } if bug
    "success"
  end

  def self.link_alerts_action(bugzilla_id, attachment_array)
    bug = Bug.where(bugzilla_id: bugzilla_id).first
    attachment_array.each do |attachment_id|
      bug.link_alert(attachment_id)
    end
    "success"
  end

  def add_ref_action(ref_type_name:, ref_data:)
    ref_type = ReferenceType.where(name: ref_type_name).first
    raise 'Invalid reference type' unless ref_type
    unless references.where(reference_type_id: ref_type.id, reference_data: ref_data).exists?
      ref = references.create(reference_type_id: ref_type.id, reference_data: ref_data)
      return ref
    end
    nil
  end

  def add_exploit_action(reference_id:, exploit_type_id:, attachment_id:, exploit_data:)
    ref = references.where(id: reference_id).first
    raise "Cannot find reference #{reference_id}" unless ref
    ref.exploits.create(exploit_type_id: exploit_type_id, attachment_id: attachment_id, data: exploit_data)
  end

  def has_draft_rules?
    rules.any? { |rule| rule.draft? }
  end

  def no_committer_ok?(new_state)
    (STATES_CLOSED.include?(new_state) && has_draft_rules?) ? false : true
  end

  # Creates a new bug in bugzilla.
  # @param [Bugzilla::Bug] bug_factory proxy interface to bugzilla.
  # @param [Hash] bug_attrs values for active record attributes on bug model.
  # @param [User] user assgined to bug.
  def self.bugzilla_create(bug_factory, bug_attrs, user = nil, skip_local_create = false)
    options = bug_attrs.to_h.slice(*%w{product component summary version description state creator opsys
                                       platform priority severity classification})
    options = options.reject { |key, value| value.nil? }

    # stub for distribted bug object
    bugzilla_bug_options = options.merge('assigned_to' => user&.email || 'vrt-incoming@sourcefire.com')
    bug_stub_hash = bug_factory.create(bugzilla_bug_options)

    if skip_local_create == false
      case options['product']
        when 'Research'
          ResearchBug.create!(options.merge(id: bug_stub_hash["id"],
                                            bugzilla_id: bug_stub_hash["id"],
                                            state: bug_attrs['state'] || 'OPEN',
                                            user_id: user&.id))
        when 'Escalations'
          EscalationBug.create!(options.merge(id: bug_stub_hash["id"],
                                              bugzilla_id: bug_stub_hash["id"],
                                              state: bug_attrs['state'] || 'OPEN',
                                              user_id: user&.id))
      end
    else
      return bug_stub_hash
    end
  end

  # Creates a new bug in bugzilla and related records and objects.
  # @param [Bugzilla::XMLRPC Token] bugzilla_session proxy interface to bugzilla.
  # @param [Hash] bug_attrs values for active record attributes on bug model.
  # @param [User] user assgined to bug.
  def self.bugzilla_create_action(bugzilla_session, bug_attrs, user:)
    # object for distributed interface for bug factory
    bug_factory = Bugzilla::Bug.new(bugzilla_session)

    # active record Bug model
    bug = bugzilla_create(bug_factory, bug_attrs, user: user)

    # pull in the first comment
    new_bug_history = bug_factory.get(bug.bugzilla_id)
    Bug.synch_history(bug_factory, new_bug_history)

    tags = bug_attrs['tag_names']
    if tags
      tags.each do |tag|
        new_tag = Tag.find_or_create_by(name: tag)
        bug.tags << new_tag
      end
    end
    # update the summary (regarding tags)
    bug.compose_summary

    bug
  end

  def update_bug_action(current_user:,
                        bugzilla_session:,
                        assignee_id:,
                        committer_id:,
                        permitted_params:,
                        new_escalation_message: nil,
                        new_escalation_state: nil)
    raise "No assignee for bug #{self.bugzilla_id}." unless assignee_id.present?
    assignee = User.where(id: assignee_id).first
    unless assignee
      Rails.logger.error("Cannot find bug assignee id = #{assignee_id.inspect} for bug #{self.bugzilla_id}")
      raise "Cannot find bug assignee for bug #{self.bugzilla_id}."
    end

    committer = committer_id.presence && User.where(id: committer_id).first

    unless committer || no_committer_ok?(permitted_params[:bug][:state])
      raise "Cannot update bug #{bugzilla_id} without committer identified"
    end
    xmlrpc = Bugzilla::Bug.new(bugzilla_session)
    Bug.process_bug_update(current_user,
                           xmlrpc,
                           self,
                           permitted_params,
                           assignee: assignee,
                           committer: committer,
                           new_escalation_message: new_escalation_message,
                           new_escalation_state: new_escalation_state)

    current_bug = xmlrpc.get(self.bugzilla_id)
    Bug.synch_history(xmlrpc, current_bug).to_s

  end

  # @param [Bugzilla::XMLRPC Token] bugzilla_session proxy interface to bugzilla.
  # @param [IO] file
  def add_attachment_action(bugzilla_session,
                            file,
                            user: nil,
                            filename:,
                            content_type:,
                            comment: nil,
                            is_patch: nil,
                            is_private: nil,
                            minor_update: nil)
    file_content = file.read
    options = {
        ids: id,
        data: XMLRPC::Base64.new(file_content),
        file_name: filename,
        summary: filename,
        content_type: content_type,
        comment: comment,
        is_patch: is_patch,
        is_private: is_private,
        minor_update: minor_update
    }.reject() { |key, value| value.nil? } #remove any nil values in the hash(bugzilla doesnt like them)
    bug_stub = Bugzilla::Bug.new(bugzilla_session)
    attachment_hash = bug_stub.add_attachment(options)
    new_attachment_id = attachment_hash["ids"][0]
    if new_attachment_id
      begin
        new_attachment = Attachment.create(
            id: new_attachment_id,
            size: file_content.length,
            bugzilla_attachment_id: new_attachment_id,
            file_name: filename,
            summary: filename,
            content_type: content_type,
            direct_upload_url:
                "https://" + Rails.configuration.bugzilla_host + "/attachment.cgi?id=" + new_attachment_id.to_s,
            creator: user&.email,
            is_private: is_private,
            is_obsolete: false,
            minor_update: minor_update
        )

      rescue Exception => e
        # the attachment id was a duplicate so i want to try creating the record anyway with a different id
         new_attachment = Attachment.create(
            size: file_content.length,
            bugzilla_attachment_id: new_attachment_id,
            file_name: filename,
            summary: filename,
            content_type: content_type,
            direct_upload_url:
                "https://" + Rails.configuration.bugzilla_host + "/attachment.cgi?id=" + new_attachment_id.to_s,
            creator: user&.email,
            is_private: is_private,
            is_obsolete: false,
            minor_update: minor_update
        )

      end

      attachments << new_attachment

      clear_rule_tested

      attachment_ids = [new_attachment.id]
      begin
        if attachment_ids.any?
          new_task = Task.create_pcap_test(id, user.id)
          TestAttachment.new(new_task,
                             bugzilla_session.token,
                             attachment_ids).send_work_msg
        end
      rescue
        #handle timeouts accordingly
        Rails.logger.error("Cannot add pcap test task: #{$!.message}")
      end
    else
      false
    end
  end

  def add_escalation_attachment_action(bugzilla_session,
                            file,
                            user: nil,
                            filename:,
                            content_type:,
                            comment: nil,
                            is_patch: nil,
                            is_private: nil,
                            minor_update: nil)
    file_content = file.read
    options = {
        ids: id,
        data: XMLRPC::Base64.new(file_content),
        file_name: filename,
        summary: filename,
        content_type: content_type,
        comment: comment,
        is_patch: is_patch,
        is_private: is_private,
        minor_update: minor_update
    }.reject() { |key, value| value.nil? } #remove any nil values in the hash(bugzilla doesnt like them)
    bug_stub = Bugzilla::Bug.new(bugzilla_session)
    attachment_hash = bug_stub.add_attachment(options)
    new_attachment_id = attachment_hash["ids"][0]
    if new_attachment_id
      new_attachment = Attachment.create(
          id: new_attachment_id,
          size: file_content.length,
          bugzilla_attachment_id: new_attachment_id,
          file_name: filename,
          summary: filename,
          content_type: content_type,
          direct_upload_url:
              "https://" + Rails.configuration.bugzilla_host + "/attachment.cgi?id=" + new_attachment_id.to_s,
          creator: user&.email,
          is_private: is_private,
          is_obsolete: false,
          minor_update: minor_update
      )
      attachments << new_attachment

    else
      false
    end
  end

  def convert_escalation_to_research(args, current_user:)
    new_summary_line = args[:research_summary]
    new_research_notes = args[:research_notes]
    bugzilla_session = args[:bugzilla_session]

    new_research_description = args[:description]

    new_bug_attrs = {}
    new_bug_attrs['product'] = "Research"
    new_bug_attrs['version'] = "No Version Specified"
    new_bug_attrs['priority'] = "Unspecified"
    new_bug_attrs['component'] = "Snort Rules"
    new_bug_attrs['classification'] = "unclassified"
    new_bug_attrs['summary'] = new_summary_line
    new_bug_attrs['status'] = "NEW"
    new_bug_attrs['assigned_to'] = "vrt-incoming@sourcefire.com"
    new_bug_attrs['description'] = new_research_description


    default_assigned_to_user = User.find_by_email("vrt-incoming@sourcefire.com")

    bug_factory = Bugzilla::Bug.new(bugzilla_session)

    bug_stub = bug_factory.create(new_bug_attrs)
    bugzilla_id = bug_stub["id"]
    new_bug_attrs.delete("assigned_to")
    new_bug_attrs.delete("Bugzilla_token")

    bugzilla_bugs = bug_factory.get(bugzilla_id)


    # default values
    vrtqa = User.where(cvs_username: 'vrtqa').first
    new_bug_attrs[:committer_id]        = vrtqa.id if vrtqa
    new_bug_attrs[:resolution]          = 'OPEN'
    new_bug_attrs[:created_at]          = bugzilla_bugs['bugs'].first['creation_time'].to_time
    new_bug_attrs[:creator]             = current_user.id.to_s

    new_research_bug = ResearchBug.create!(new_bug_attrs.merge(id: bugzilla_id,
                                                               product: "Research",
                                                               bugzilla_id: bugzilla_id,
                                                               user_id: default_assigned_to_user.id,
                                                               state: "NEW"))

    if new_research_notes.present?
      new_research_bug.research_notes = new_research_notes
    end

    new_research_bug.save

    new_comments = bug_factory.comments(ids: [ bugzilla_id ])
    new_comments['bugs'].each do |ignore_id, comment_hash|
      comment_hash['comments'].each do |comment_curr|
        next if Note.where(id: comment_curr['id']).first.present? #we already have this one
        if comment_curr['text'].downcase.strip.start_with?('commit')
          note_type = 'committer'
        elsif comment_curr['text'].start_with?('Created attachment')
          note_type = 'attachment'
        else
          note_type = 'research'
        end
        comment = comment_curr['text'].strip
        creation_time = comment_curr['creation_time'].to_time
        note = Note.where(id: comment_curr['id']).first
        if note.present?
          note.update_attributes({
                                     author:     comment_curr['creator'],
                                     comment:    comment,
                                     bug_id:     bugzilla_id,
                                     note_type:  note_type,
                                     notes_bugzilla_id: comment_curr['id'],
                                     created_at: creation_time
                                 })
        else
          Note.create({
                          id:         comment_curr['id'],
                          author:     comment_curr['creator'],
                          comment:    comment,
                          bug_id:     bugzilla_id,
                          note_type:  note_type,
                          created_at: creation_time,
                          notes_bugzilla_id: comment_curr['id']
                      })
        end
      end

      bug_factory.update(ids: self.bugzilla_id,
                         depends_on: {add: [new_research_bug.bugzilla_id]})
    end


    self.giblets.each do |gib|
      new_research_bug.send(gib.gib.class.to_s.downcase.pluralize) << gib.gib
      new_gib = Giblet.create(:bug_id => new_research_bug.id, :gib_type => gib.gib.class.to_s, :gib_id => gib.gib.id)
      new_gib.name = new_gib.display_name
      new_gib.save
    end

    self.attachments.each do |attachment|
      new_attachment = attachment.dup
      new_attachment.bug_id = new_research_bug.id
      new_attachment.save
    end

    copy_notes_to_bug(new_research_bug.id, bug_factory: bug_factory)
    if args[:research_notes].present?
      Note.process_note({
                            id: new_research_bug.id,
                            comment: args[:research_notes],
                            note_type: 'research',
                            author: current_user.email
                        },
                        bug_factory)
    end

    new_research_bug

  end

end
