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
  # has_many :pcaps, -> { where("attachments.file_name like '%.pcap'") }, class_name: 'Attachment'
  has_many :pcaps, -> { pcap }, class_name: 'Attachment'
  has_many :tasks, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :test_reports

  has_many :alerts, through: :attachments
  has_many :local_alerts, through: :attachments

  accepts_nested_attributes_for :rules

  scope :open_bugs, -> { where('state in (?)', ['OPEN', 'ASSIGNED', 'REOPENED']) }
  scope :closed, -> { where('state in (?)', ['FIXED', 'WONTFIX', 'LATER', 'INVALID', 'DUPLICATE']) }
  scope :pending, -> { where(state: "PENDING") }
  scope :open_pending, -> {where('state in (?)', ['PENDING','OPEN', 'ASSIGNED', 'REOPENED'])}
  scope :by_component, ->(component) { where('component = ?', component) }

  scope :permit_class_level, ->(class_level) { where("classification <= :class_pattern", class_pattern: "%#{class_level}%") }

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
        .select(:file_name, 'alerts.rule_id')
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

  def update_bug(xmlrpc, options)
    unless xmlrpc.nil?
      # the bugzilla session is where we authenticate
      changed_bug = Bugzilla::Bug.new(xmlrpc).update(options.to_h)
    end
    changed_bug
  end

  def self.bugs_with_search(query_params)
    if query_params[:bugzilla_max] == '' || query_params[:bugzilla_max].nil?
      Bug.where(query_params)
    else
      nil
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
      when "team-bugs"
        if current_user.has_role?('manager')
          current_user.children.map{ |cw| cw.bugs }[0] || []
        else
          current_user.siblings.map{ |cw| cw.bugs }[0] || []
        end
      when "advance-search"
        Bug.bugs_with_search(search_options) || Bug.all
      else
        nil
    end
  end

  def clear_rule_tested
    rules.update_all(tested: false)
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

  def self.get_new_bug_state(bug, state, editor_email)
    updated_state = state
    updated_state = 'NEW' if editor_email == 'vrt-incoming@sourcefire.com' && bug.resolution == 'OPEN'
    updated_state = 'ASSIGNED' unless (editor_email == 'vrt-incoming@sourcefire.com') || (%w(RESOLVED REOPENED).include? bug.status) || state == 'PENDING'
    updated_state = nil if updated_state == bug.state
    state_params = {}

    case updated_state
    when 'NEW'
      state_params[:status] = updated_state
      state_params[:resolution] = 'OPEN'
      state_params[:comment] = { comment: "This bug has been set back to NEW. #{bug.user.email} is no longer assigned to this bug." }
    when 'ASSIGNED'
      state_params[:status] = updated_state
      state_params[:resolution] = 'OPEN'
      state_params[:comment] = { comment: "This bug is now ASSIGNED to #{editor_email}." }
      state_params[:assigned_at] = Time.now
    when 'PENDING'
      state_params[:status] = 'RESOLVED'
      state_params[:resolution] = updated_state
      state_params[:comment] = { comment: "This bug is now RESOLVED - #{updated_state}." }
      state_params[:pending_at] = Time.now
      if bug.state == 'REOPENED'
        state_params[:rework_time] = bug.reopened_at? ? ((state_params[:pending_at] - bug.reopened_at) / 86_400).ceil : nil
      else
        state_params[:work_time] = bug.assigned_at? ? ((state_params[:pending_at] - bug.assigned_at) / 86_400).ceil : nil
      end
    when 'FIXED', 'WONTFIX', 'INVALID', 'DUPLICATE', 'LATER'
      state_params[:status] = 'RESOLVED'
      state_params[:resolution] = updated_state
      state_params[:comment] = { comment: "This bug is now RESOLVED - #{updated_state}." }
      state_params[:resolved_at] = Time.now
      state_params[:review_time] = bug.pending_at? ? ((state_params[:resolved_at] - bug.pending_at) / 86_400).ceil : nil
    when 'REOPENED'
      state_params[:status] = updated_state
      state_params[:resolution] = 'OPEN'
      state_params[:comment] = { comment: "This bug is now #{updated_state}." }
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

  def can_set_pending?
    exploits_complete? && rules_parsed? && docs_complete?
  end

  def exploits_complete?
    exploits.each{ |expl| return false if expl.attachment.nil? }
    true
  end

  def rules_parsed?
    rules.each{ |rule| return false unless rule.parsed? }
    true
  end

  def docs_complete?
    rules.all? { |rule| rule.doc_complete? }
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

  def summary_references
    references = []
    ReferenceType.where.not(bugzilla_format: nil).each do |ref_type|
      summary.scan(/#{ref_type.bugzilla_format}/i).each do |match|
        references << Reference.where(reference_type_id: ref_type.id, reference_data: match[0]).first_or_create
      end
    end
    references.uniq
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

  def bugzilla_synch_needed?
    tags.empty? && !summary_tag_array.empty?
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

  def self.synch_history(xmlrpc, new_bugs)
    unless new_bugs.empty?
      new_bugs['bugs'].each do |item|
        bug_id = item['id']
        new_comments = xmlrpc.comments(ids: [bug_id])
        bug = Bug.find(bug_id)
        unless new_comments.empty?

          ActiveRecord::Base.transaction do
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
		                created_at: creation_time
	                })
                else
                  Note.create({
	                  id:         c['id'],
                    author:     c['author'],
                    comment:    comment,
                    bug_id:     bug_id,
                    note_type:  note_type,
                    created_at: creation_time
                  })
                end

              end
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
        bug = Bug.find(bug_id)
        unless new_attachments.empty?
          new_attachments['bugs'][bug_id.to_s].each do |attachment|
            local_attachment = Attachment.where(bugzilla_attachment_id: attachment['id']).first
            if local_attachment.present?
              if attachment['is_obsolete'] == true
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
            :attachment_array => bug.attachments.map{|a| a.id},
        }
        new_task = Task.create(
            :bug  => options[:bug],
            :task_type     => options[:task_type],
            :user => current_user
        )
        begin
          TestAttachment.new(new_task, xmlrpc_token, options[:attachment_array]).send_work_msg
        rescue Exception => e
          #handle timeouts accordingly
          Rails.logger.info("Rails encountered an error but is powering through it. #{e.message}")
        end
      end
    end
  end

  def self.bugzilla_import(current_user, xmlrpc, xmlrpc_token, new_bugs)
    unless new_bugs.empty?
      new_bugs['bugs'].each do |item|
        bug_id = item['id']
        new_attachments = xmlrpc.attachments(ids: [bug_id])
        new_comments = xmlrpc.comments(ids: [bug_id])
        bug = Bug.find_or_create_by(bugzilla_id: bug_id)

        bug.id             = bug_id
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
          new_generated_user.roles << Role.where(role:"analyst")
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
        unless new_attachments.empty?

          new_attachments['bugs'][bug_id.to_s].each do |attachment|
            local_attachment = Attachment.where(bugzilla_attachment_id: attachment['id']).first
            if local_attachment.present?
              if attachment['is_obsolete'] == true
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
            :attachment_array => bug.attachments.map{|a| a.id},
        }
        new_task = Task.create(
            :bug  => options[:bug],
            :task_type     => options[:task_type],
            :user => current_user
        )
        begin
          TestAttachment.new(new_task, xmlrpc_token, options[:attachment_array]).send_work_msg
        rescue Exception => e
          #handle timeouts accordingly
          Rails.logger.info("Rails encountered an error but is moving through it. #{e.message}")
        end

        bug.research_notes ||= Note::TEMPLATE_RESEARCH
        unless new_comments.empty?

          ActiveRecord::Base.transaction do
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
                  note.update_attributes({
                    author:     c['author'],
                    comment:    comment,
                    bug_id:     bug_id,
                    note_type:  note_type,
                    created_at: creation_time
	                })
                else
                  Note.create({
                    id:         c['id'],
                    author:     c['author'],
                    comment:    comment,
                    bug_id:     bug_id,
                    note_type:  note_type,
                    created_at: creation_time
                  })
                end

              end
            end
          end
        end
        bug.save
      end
    end
    true
  end

  def self.bugzilla_light_import(current_user, xmlrpc, xmlrpc_token, new_bugs)
    unless new_bugs.empty?
      new_bugs['bugs'].each do |item|
        bug_id = item['id']

        Bug.find_or_create_by(bugzilla_id: bug_id) do |new_record|
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

  def bugzilla_summary_sids_replace(xmlrpc, sids)
    unless xmlrpc.nil?
      sids.delete_if { |sid| sid.zero? }
      unless sids.nil? || sids.empty?
        self.summary = "[SID] #{sids.to_ranges_compact_string} #{summary_without_sids}"
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
      bug.rules << rule
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
end
