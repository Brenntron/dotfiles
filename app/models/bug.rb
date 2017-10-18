class Bug < ApplicationRecord

  has_many :bugs_rules
  has_many :rules, through: :bugs_rules
  has_and_belongs_to_many :tags, dependent: :destroy
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

  accepts_nested_attributes_for :rules

  LIBERTY_CLEAR                         = "CLEAR"
  LIBERTY_EMBARGO                       = "EMBARGO"

  scope :open_bugs, -> { where('state in (?)', ['OPEN', 'ASSIGNED', 'REOPENED']) }
  scope :closed, -> { where('state in (?)', ['FIXED', 'WONTFIX', 'LATER', 'INVALID', 'DUPLICATE']) }
  scope :pending, -> { where(state: "PENDING") }
  scope :open_pending, -> {where('state in (?)', ['PENDING','OPEN', 'ASSIGNED', 'REOPENED'])}
  scope :by_component, ->(component) { where('component = ?', component) }

  scope :permit_class_level, ->(class_level) { where("classification <= ? ", Bug.classifications[class_level]) }

  attr_accessor :import_report

  def liberty_clear?
    LIBERTY_CLEAR == self.liberty
  end

  def liberty_embargo?
    LIBERTY_EMBARGO == self.liberty
  end

  def initialize_report
    @import_report = {}
    @import_report[:new_rules] = 0
    @import_report[:new_attachments] = 0
    @import_report[:new_notes] = 0
    @import_report[:new_tags] = 0
    @import_report[:new_refs] = 0
  end

  def compile_import_report(initial_bug_state = nil)
    total_report = @import_report.clone
    if initial_bug_state.present?
      total_report[:changed_bug_columns] = ((self.attributes.to_h.to_a) - (initial_bug_state.attributes.to_h.to_a))
    end
    total_report[:total_changes] = total_report[:new_rules] + total_report[:new_attachments] + total_report[:new_notes] + total_report[:new_tags] + total_report[:new_refs] + total_report[:changed_bug_columns].size
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
    elsif status == 'RESOLVED'
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

  def update_bug(xmlrpc, options)
    unless xmlrpc.nil?
      # the bugzilla session is where we authenticate
      changed_bug = Bugzilla::Bug.new(xmlrpc).update(options.to_h)
    end
    changed_bug
  end

  def self.bugs_with_search(query_params)
    case
      when query_params[:bugzilla_max].present?
        nil
      when query_params[:summary].present?
        summary_param = query_params.delete(:summary)
        Bug.where(query_params).where('summary LIKE ?', "%#{summary_param}%")
      else
        Bug.where(query_params)
    end
  end

  def self.query(current_user, named_query, search_options)
    case named_query
      when NilClass
        nil
      when "all-bugs"
        @bugs = Bug.all
      when "open-bugs"
        @bugs = Bug.open_bugs
      when "pending-bugs"
        @bugs = Bug.pending
      when 'fixed-bugs'
        Bug.closed
      when "my-bugs"
        current_user.bugs
      when "my-open-bugs"
        current_user.bugs.open_bugs
      when "team-bugs"
        if current_user.is_on_team?
          if current_user.has_role?('manager')
            Bug.where(user_id: [current_user.id] + current_user.siblings.map{ |cw| cw.id } + current_user.children.map{ |cw| cw.id }) || []
          else
            Bug.where(user_id: current_user.siblings.map{ |cw| cw.id } << current_user.id) || []
          end
        else
          current_user.bugs
        end
      when "advance-search"
        Bug.bugs_with_search(search_options) || Bug.all
      else
        nil
    end
  end

  def clear_rule_tested
    bugs_rules.update_all(tested:false)
  end

  def update_attachments(xmlrpc)
    fields = ['file_name', 'id', 'last_change_time', 'is_obsolete', 'size']

    # Now fetch the bug attachments and create them if needed
    xmlrpc.attachments(ids: [bugzilla_id], include_fields: fields)['bugs'][bugzilla_id.to_s].each do |attachment|
      next if attachment['file_name'] !~ /\.pcap$/
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

  def self.get_new_bug_state(bug, state, state_comment, editor_email)
    updated_state = state
    updated_state = 'NEW' if editor_email == 'vrt-incoming@sourcefire.com' && bug.resolution == 'OPEN' && state == 'NEW'
    updated_state = 'ASSIGNED' unless (editor_email == 'vrt-incoming@sourcefire.com') || (%w(RESOLVED REOPENED).include? bug.status) || ['PENDING','FIXED', 'WONTFIX', 'LATER', 'INVALID', 'DUPLICATE'].include?(state)
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
      state_params[:assigned_at] = Time.now
    when 'PENDING'
      state_params[:status] = 'RESOLVED'
      state_params[:resolution] = updated_state
      state_params[:comment] = { comment: "#{state_comment} \nThis bug is now RESOLVED - #{updated_state}." }
      state_params[:pending_at] = Time.now
      if bug.state == 'REOPENED'
        state_params[:rework_time] = bug.reopened_at? ? ((state_params[:pending_at] - bug.reopened_at) / 86_400).ceil : nil
      else
        state_params[:work_time] = bug.assigned_at? ? ((state_params[:pending_at] - bug.assigned_at) / 86_400).ceil : nil
      end
    when 'FIXED', 'WONTFIX', 'INVALID', 'DUPLICATE', 'LATER'
      state_params[:status] = 'RESOLVED'
      state_params[:resolution] = updated_state
      state_params[:comment] = { comment: "#{state_comment} \nThis bug is now RESOLVED - #{updated_state}." }
      state_params[:resolved_at] = Time.now
      state_params[:review_time] = bug.pending_at? ? ((state_params[:resolved_at] - bug.pending_at) / 86_400).ceil : nil
    when 'REOPENED'
      state_params[:status] = updated_state
      state_params[:resolution] = 'OPEN'
      state_params[:comment] = { comment: "#{state_comment} \nThis bug is now #{updated_state}." }
      state_params[:reopened_at] = Time.now
    when 'OPEN'
      state_params[:status] = updated_state
      state_params[:resolution] = 'OPEN'
      state_params[:comment] = { comment: "#{state_comment} \nThis bug is now #{updated_state}." }
      state_params[:reopened_at] = Time.now
    end


    #return state params hash
    state_params
  end

  def priority_sort
    if priority.nil?
      priority = 'Unspecified'
    else
      priority
    end
  end

  def exploits_complete?
    exploits.all? { |expl| expl.attachment.present? }
  end

  def rules_parsed?
    rules.all? { |rule| rule.parsed? }
  end

  def docs_complete?
    rules.all? { |rule| rule.doc_complete? }
  end

  def resolve_errors
    unless @resolve_errors
      @resolve_errors = []

      @resolve_errors << "Please assign attachments to exploits." unless exploits_complete?
      @resolve_errors << "Please complete the summary for rule docs." unless docs_complete?
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
    parsed_summary[:tags] = summary_tags
    parsed_summary[:sids] = summary_sids
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
      rule = Rule.find_or_load(sid, gid)
      if rule
        @import_report[:new_rules] += 1 unless self.rules.include? rule
        if import_type != "status"
          rules << rule unless self.rules.include? rule
        end
      end
    end
  end

  def summary_references
    references = []
    ReferenceType.where.not(bugzilla_format: nil).each do |ref_type|
      summary.scan(/#{ref_type.bugzilla_format}/i).each do |match|
        references << Reference.where(reference_type_id: ref_type.id, reference_data: match[0]).first_or_create
      end
    end
    references.uniq
  end

  def load_references(summary_references)
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

  def update_summary(summary_given)
    update!(summary: summary_given)

    load_rules_from_sids(summary_sids)
    compose_summary
    load_references(summary_references)
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

  def check_permission(current_user)
    User.class_levels[current_user.class_level] >= Bug.classifications[self.classification]
  end

  def create_tags_from_summary(summary_tags)
    summary_tags.each do |tag|
      Tag.find_or_create_by(name: tag)
    end
  end

  def add_attachment(xmlrpc, file)
    Bugzilla::Bug.new(xmlrpc).attach_file(bugzilla_id, file)
  end

  ####methods for bug importing######

  def load_tags_from_summary(tags, import_type='import')
    tags.each do |tag|
      @import_report[:new_tags] += 1 unless self.tags.include?(tag)
      if import_type != "status"
        self.tags << tag unless self.tags.include?(tag)
      end
    end
  end

  def load_refs_from_summary(refs, import_type='import_type')
    refs.each do |ref|
      @import_report[:new_refs] += 1 unless self.references.map {|r| r.reference_data}.include? ref.reference_data
      if import_type != "status"
        self.references << ref unless self.references.map {|r| r.reference_data}.include? ref.reference_data
      end
      Exploit.find_exploits(ref)
    end
  end

  ####end method group###############

  def self.synch_history(xmlrpc, new_bugs)
    unless new_bugs.empty?
      new_bugs['bugs'].each do |item|
        bug_id = item['id']
        new_comments = xmlrpc.comments(ids: [bug_id])
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
                    author:     c['author'],
		                comment:    comment,
		                bug_id:     bug_id,
                    note_type:  note_type,
                    notes_bugzilla_id: c['id'],
                    created_at: creation_time
	                })
                else
                  Note.create({
	                  id:         c['id'],
                    author:     c['author'],
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
                new_attach_record.direct_upload_url = "https://bugzilla.vrt.sourcefire.com/attachment.cgi?id=" + new_attach_record.id = attachment['id'].to_s
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

  def self.publish_research_notes(bugzilla_session, current_user, bug)

    note = bug.research_notes

    notes_to_append = note + "\n\n--------------------------------------------------\n"

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
      if att.file_name.include? '.pcap'
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

    Note.process_note(options, bugzilla_session)

  end

  def self.process_bug_update(current_user, bugzilla_session, bug, permitted_params)
    bug.initialize_report
    bug_is_being_resolved = bug.state != "PENDING" ? false : true

    ###
    tags = permitted_params[:bug][:tag_names]
    editor = User.find(permitted_params[:bug][:user_id])
    reviewer = User.find(permitted_params[:bug][:committer_id])
    updated_bug_state = Bug.get_new_bug_state(bug, permitted_params[:bug][:state], permitted_params[:bug][:state_comment], editor.email)
    ###

    ###
    options = {
        :ids => permitted_params[:id],
        :assigned_to => editor.email,
        :status => updated_bug_state[:status],
        :resolution => updated_bug_state[:resolution],
        :comment => updated_bug_state[:comment],
        :qa_contact => reviewer.email
    }
    update_params = {
        :user => editor,
        :state => updated_bug_state[:state],
        :status => updated_bug_state[:status],
        summary: updated_bug_state[:summary],
        :resolution => updated_bug_state[:resolution],
        :assigned_at => updated_bug_state[:assigned_at],
        :pending_at => updated_bug_state[:pending_at],
        :resolved_at => updated_bug_state[:resolved_at],
        :reopened_at => updated_bug_state[:reopened_at],
        :work_time => updated_bug_state[:work_time],
        :rework_time => updated_bug_state[:rework_time],
        :review_time => updated_bug_state[:review_time],
        :committer => reviewer
    }

    if permitted_params[:bug][:new_research_notes]
      update_params = {
          :research_notes => permitted_params[:bug][:new_research_notes]
      }
    elsif permitted_params[:bug][:new_committer_notes]
      update_params = {
          :committer_notes => permitted_params[:bug][:new_committer_notes]
      }
    end
    ###

    ###
    #if a comment is made about a state then add it to the history here.
    if permitted_params[:bug][:state_comment]
      note_options = {
          :id => permitted_params[:id],
          :comment => permitted_params[:bug][:state_comment],
          :note_type => "research",
          :author => current_user.email,
      }
      Note.process_note(note_options, bugzilla_session)
    end
    # update the tags
    bug.tags.delete_all if bug.tags.exists?
    if tags
      tags.each do |tag|
        new_tag = Tag.find_or_create_by(name: tag)
        bug.tags << new_tag
      end
    end
    ###

    # update the summary
    # (do this first so we can compose the summary properly to send to bugzilla)
    bug.update_summary(permitted_params[:bug][:summary])

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

    # update buzilla (if needed)
    options.reject! { |k, v| v.nil? } if options
    Bugzilla::Bug.new(bugzilla_session).update(options.to_h) unless options.blank?

    update_params[:product] = permitted_params[:bug][:product]
    update_params[:component] = permitted_params[:bug][:component]
    update_params[:summary] = permitted_params[:bug][:summary]
    update_params[:version] = permitted_params[:bug][:version]
    update_params[:state] = permitted_params[:bug][:state]
    update_params[:opsys] = permitted_params[:bug][:opsys]
    update_params[:platform] = permitted_params[:bug][:platform]
    update_params[:priority] = permitted_params[:bug][:priority]
    update_params[:severity] = permitted_params[:bug][:severity]
    update_params[:classification] = permitted_params[:bug][:classification]

    # update the database
    update_params.reject! { |k, v| v.nil? }
    Bug.update(permitted_params[:id], update_params)

    bug.reload
    if bug.state == "PENDING" || (bug_is_being_resolved == true && bug.state != "PENDING")
      bug_is_being_resolved = !bug_is_being_resolved
    end

    if bug_is_being_resolved
     publish_research_notes(bugzilla_session, current_user, bug)
    end

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


  def self.bugzilla_import(current_user, xmlrpc, xmlrpc_token, new_bugs, progress_bar = nil, import_type = "import")
    import_type = import_type.blank? ? "import" : import_type
    total_bugs = []
    unless new_bugs['bugs'].empty?
      new_bugs['bugs'].each do |item|

        progress_bar.update_attribute("progress", 10) unless progress_bar.blank?

        bug_id = item['id']
        new_attachments = xmlrpc.attachments(ids: [bug_id])
        new_comments = xmlrpc.comments(ids: [bug_id])

        #Update Bug record attributes from bugzilla############
        bug = Bug.find_or_create_by(bugzilla_id: bug_id)

        bug.initialize_report

        bug.id = bug_id
        bug.summary        = item['summary']
        bug.classification = 'unclassified'
        bug.status     = item['status']
        bug.resolution = item['resolution']
        bug.resolution = 'OPEN' if bug.resolution.empty?

        bug.state     = bug.get_state(item['status'], item['resolution'], item['assigned_to'])
        bug.priority  = item['priority']
        bug.component = item['component']
        bug.product   = item['product']

        bug.created_at = item['creation_time'].to_time
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
        if import_type != "status"
          bug.save
        end
        #end Bug attributes update##################


        #Create/update Bug User relationships
        creator = User.where('email=?', item['creator']).first
        new_user = User.where('email=?', item['assigned_to']).first
        new_committer = User.where('email=?', item['qa_contact']).first
        if creator.nil?
          User.create_by_email(item['creator'])
          new_creator = User.where(email: item['creator']).first
          bug.creator = new_creator.id
        else
          bug.creator = creator.id
        end
        if new_user.nil?
          User.create_by_email(item['assigned_to'])
          new_generated_user = User.where(email: item['assigned_to']).first
          bug.user = new_generated_user
        else
          bug.user = new_user
        end
        if new_committer.nil?
          User.create_by_email(item['qa_contact'])
          new_generated_committer = User.where(email: item['qa_contact']).first
          new_generated_committer.roles << Role.where(role:"committer")
          bug.committer = new_generated_committer
        else
          bug.committer = new_committer
        end
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
              bug.import_report[:new_attachments] += 1
              local_attachment = Attachment.create do |new_attach_record|
                new_attach_record.id = attachment['id']
                new_attach_record.size = attachment['size']
                new_attach_record.bugzilla_attachment_id = attachment['id'] #this is the id comming from bugzilla
                new_attach_record.file_name = attachment['file_name']
                new_attach_record.summary = attachment['summary']
                new_attach_record.content_type = attachment['content_type']
                new_attach_record.direct_upload_url = "https://bugzilla.vrt.sourcefire.com/attachment.cgi?id=" + new_attach_record.id = attachment['id'].to_s
                new_attach_record.creator = attachment['attacher']
                new_attach_record.is_private = attachment['is_private']
                new_attach_record.is_obsolete = attachment['is_obsolete']
                new_attach_record.minor_update = false
                new_attach_record.created_at = attachment['creation_time'].to_time
              end
            end
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
                    note.update_attributes(author: c['author'],
                                           comment: comment,
                                           bug_id: bug_id,
                                           note_type: note_type,
                                           notes_bugzilla_id: c['id'],
                                           created_at: creation_time)
                  end
                else
                  bug.import_report[:new_notes] += 1
                  unless import_type == "status"
                    Note.create(id: c['id'],
                                author: c['author'],
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

              unless bug_has_published_notes
                last_committer_note = bug.notes.last_committer_note.first
                if last_committer_note.present?
                  committer_note_text_area = ""
                  if last_committer_note
                    committer_note_text_area = Note.parse_from_note(last_committer_note.comment,"Committer Notes:", true) + "\n"
                  end
                  new_note = Note.where(notes_bugzilla_id: nil,bug_id: bug_id).committer_note.first_or_create
                  new_note.note_type = 'committer'
                  new_note.comment = new_note.comment.nil? ? committer_note_text_area : committer_note_text_area + "\n" + new_note.comment
                  new_note.author = last_committer_note.nil? ? current_user.email : last_committer_note.author
                  new_note.created_at = Time.now.to_time
                  new_note.save
                end
              end

              #prepopulating research notes in notes tab
              latest_research = bug.notes.where("note_type=? and comment like 'Research Notes:%'", "research").reverse_chron.first
              if latest_research.present? && !(bug_has_notes)
                new_draft = Note.parse_from_note(latest_research.comment, "Research Notes:", false)
                #new_note = Note.new({
                #                        comment: new_draft,
                #                        note_type: 'research',
                #                        author: current_user.email,
                #                        bug_id:     bug_id
                #                    })
                #new_note.save
                bug.research_notes = new_draft
              end
            end

          end
        end

        progress_bar.update_attribute("progress", 30) unless progress_bar.blank?

        parsed = bug.parse_summary
        progress_bar.update_attribute("progress", 50) unless progress_bar.blank?
        bug.load_rules_from_sids(parsed[:sids], bug.component, import_type)
        progress_bar.update_attribute("progress", 60) unless progress_bar.blank?
        bug.load_tags_from_summary(parsed[:tags], import_type)

        progress_bar.update_attribute("progress", 75) unless progress_bar.blank?
        bug.load_refs_from_summary(parsed[:refs], import_type)

        progress_bar.update_attribute("progress", 90) unless progress_bar.blank?

        #save the bug and clear all rule tests unless the import action is a status check
        if import_type != "status"
          bug.save
          bug.clear_rule_tested
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
          new_record = Bug.new(bugzilla_id: bug_id)

          new_record.id             = bug_id
          new_record.summary        = item['summary']
          new_record.classification = item['classification'].parameterize.downcase.underscore

          new_record.status     = item['status']
          new_record.resolution = item['resolution']
          new_record.resolution = 'OPEN' if new_record.resolution.empty?

          new_record.state     = new_record.get_state(item['status'], item['resolution'], item['assigned_to'])
          new_record.priority  = item['priority']
          new_record.component = item['component']
          new_record.product   = item['product']

          new_record.created_at = item['creation_time'].to_time
          last_change_time      = item['last_change_time'].to_time
          if new_record.state == 'NEW'
            # do nothing
          elsif new_record.state == 'ASSIGNED'
            new_record.assigned_at = last_change_time
          elsif new_record.state == 'PENDING'
            new_record.pending_at = last_change_time
          elsif new_record.state == 'REOPENED'
            new_record.reopened_at = last_change_time
          else
            new_record.resolved_at = last_change_time
          end
          creator = User.where('email=?', item['creator']).first
          new_user = User.where('email=?', item['assigned_to']).first
          new_committer = User.where('email=?', item['qa_contact']).first
          if creator.nil?
            User.create_by_email(item['creator'])
            new_creator = User.where(email: item['creator']).first
            new_record.creator = new_creator.id
          else
            new_record.creator = creator.id
          end
          if new_user.nil?
            User.create_by_email(item['assigned_to'])
            new_generated_user = User.where(email: item['assigned_to']).first
            new_generated_user.roles << Role.where(role:"analyst")
            new_record.user = new_generated_user
          else
            new_record.user = new_user
          end
          if new_committer.nil?
            User.create_by_email(item['qa_contact'])
            new_generated_committer = User.where(email: item['qa_contact']).first
            new_generated_committer.roles << Role.where(role:"committer")
            new_record.committer = new_generated_committer
          else
            new_record.committer = new_committer
          end

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
    self.summary = "[SID] #{to_ranges_compact_string(sids)} #{summary_without_sids}"
    save!
    # update_bugzilla_attributes(xmlrpc, ids: [bugzilla_id], summary: self.summary )
    self.summary
  end

  def bug_state(xmlrpc, notes=nil, status, resolution)
    deps = open_dependencies(xmlrpc)
    if deps.size > 0
      return { error: "This bug currently has open dependencies: #{deps}" }
    else
      self.bug_state = resolution
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
        self.summary = "[SID] #{to_ranges_compact_string(sids)} #{summary_without_sids}"
      end
      options = { ids: [bugzilla_id],
                  summary: summary }
      Bugzilla::Bug.new(xmlrpc).update(options.to_h)
    end
  end

  def summary_without_sids
    summary.gsub(/\[SID\]\s*?([\d\s,\-]+)(?:\s)?/, '')
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
      references.create(reference_type_id: ref_type.id, reference_data: ref_data)
    end
  end

  def add_exploit_action(reference_id:, exploit_type_id:, attachment_id:, exploit_data:)
    ref = references.where(id: reference_id).first
    raise "Cannot find reference #{reference_id}" unless ref
    ref.exploits.create(exploit_type_id: exploit_type_id, attachment_id: attachment_id, data: exploit_data)
  end
end
