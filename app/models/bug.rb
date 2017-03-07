class Bug < ApplicationRecord

  has_and_belongs_to_many :rules
  has_and_belongs_to_many :tags, dependent: :destroy
  has_and_belongs_to_many :references, dependent: :destroy
  belongs_to :user, optional: true
  belongs_to :committer, class_name: 'User', optional: true

  has_many :exploits, through: :references
  has_many :attachments, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :notes, dependent: :destroy

  accepts_nested_attributes_for :references
  accepts_nested_attributes_for :rules

  scope :open, -> { where('state in (?)', ['OPEN', 'ASSIGNED', 'REOPENED']) }
  scope :closed, -> { where('state in (?)', ['FIXED', 'WONTFIX', 'LATER', 'INVALID', 'DUPLICATE']) }
  scope :pending, -> { where(state: "PENDING") }
  scope :by_component, ->(component) { where('component = ?', component) }

  scope :allowed_editors, ->(bug) {User.all.reject { |u| u.id == bug.committer_id }}
  scope :allowed_committers, ->(bug) {User.all.reject { |u| u.id == bug.committer_id }}

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

  def self.bugs_with_search(params)
    if params[:bugzilla_max] == '' || params[:bugzilla_max].nil?
      query_params = params.reject { |k, v| (v == '' || v.is_a?(Array) || k =='tag_name') }
      count = 0
      query = ''
      query_params.each do |k, v|
        count = count + 1
        query = query + k + "='" + v.gsub("'", "\\'") + "'"
        query = query + ' && ' if count != query_params.to_h.size
      end
      Bug.where(query)
    end
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
      state_params['status'] = updated_state
      state_params['resolution'] = 'OPEN'
      state_params['comment'] = { comment: "This bug has been set back to NEW. #{bug.user.email} is no longer assigned to this bug." }
    when 'ASSIGNED'
      state_params['status'] = updated_state
      state_params['resolution'] = 'OPEN'
      state_params['comment'] = { comment: "This bug is now ASSIGNED to #{editor_email}." }
      state_params['assigned_at'] = Time.now
    when 'PENDING'
      state_params['status'] = 'RESOLVED'
      state_params['resolution'] = updated_state
      state_params['comment'] = { comment: "This bug is now RESOLVED - #{updated_state}." }
      state_params['pending_at'] = Time.now
      if bug.state == 'REOPENED'
        state_params['rework_time'] = ((pending_at - bug.reopened_at) / 86_400).ceil
      else
        state_params['work_time'] = ((pending_at - bug.assigned_at) / 86_400).ceil
      end
    when 'FIXED', 'WONTFIX', 'INVALID', 'DUPLICATE', 'LATER'
      state_params['status'] = 'RESOLVED'
      state_params['resolution'] = updated_state
      state_params['comment'] = { comment: "This bug is now RESOLVED - #{updated_state}." }
      state_params['resolved_at'] = Time.now
      state_params['review_time'] = ((resolved_at - bug.pending_at) / 86_400).ceil
    when 'REOPENED'
      state_params['status'] = updated_state
      state_params['resolution'] = 'OPEN'
      state_params['comment'] = { comment: "This bug is now #{updated_state}." }
      state_params['reopened_at'] = Time.now
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
    exploits.each do |expl|
      if expl.attachment.nil?
        return false
      end
    end
    true
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

  def summary_sids
    sids = []
    unless summary.nil?
      summary.scan(/\[SID\]\s*([\d,\-]+)\b(?:\s)?/).each do |match|
        match[0].split(/[,\s]/).each do |part|
          if part =~ /(\d+)-(\d+)/
            sids << eval("#{$1}..#{$2}").to_a
          else
            sids << part.gsub(/\s+/, '').to_i
          end
        end
      end
    end
    sids.flatten.sort.uniq.delete_if { |a| a <= 0 }
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

  def resolution_time
    if resolved_at.present?
      ((resolved_at - created_at) / 86_400).ceil
    else
      0
    end
  end

  def associate_references(rule_text)
    references = []
    rule_text.split(';').each { |r| references << r.strip.gsub!('reference:', '') if r.match(/reference\W*:/) }
    references.each do |r|
      r = r.split(',')
      unless r[1].empty?
        new_reference = Reference.find_or_create_by(reference_type: ReferenceType.where(name: r[0]).first, reference_data: r[1])
        self.references << new_reference unless self.references.include?(new_reference)
      end
    end
  end

  private

  def create_tags_from_summary(summary_tags)
    summary_tags.each do |tag|
      Tag.create(name: tag)
    end
  end

  def add_attachment(xmlrpc, file)
    Bugzilla::Bug.new(xmlrpc).attach_file(bugzilla_id, file)
  end

  def self.bugzilla_import(xmlrpc, new_bugs)
    unless new_bugs.empty?
      new_bugs['bugs'].each do |item|
        bug_id = item['id']
        new_attachments = xmlrpc.attachments(ids: [bug_id])
        new_comments = xmlrpc.comments(ids: [bug_id])

        Bug.find_or_create_by(bugzilla_id: bug_id) do |new_record|
          new_record.id             = bug_id
          new_record.summary        = item['summary']
          new_record.classification = 'unclassified'

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
            new_record.creator = User.create(kerberos_login: 'generated',
                                             cvs_username: item['creator'].gsub("@#{Rails.configuration.bugzilla_domain}", '').gsub('@sourcefire.com', ''),
                                             email: item['creator'],
                                             password: 'password',
                                             password_confirmation: 'password',
                                             committer: 'false')
          else
            new_record.creator = creator
          end
          if new_user.nil?
             new_generated_user = User.new(kerberos_login: 'generated',
                                          cvs_username: item['assigned_to'].gsub("@#{Rails.configuration.bugzilla_domain}", '').gsub('@sourcefire.com', ''),
                                          email: item['assigned_to'],
                                          password: 'password',
                                          password_confirmation: 'password',
                                          committer: 'false')
            new_generated_user.roles = Role.where(role:"analyst")
            new_generated_user.save
            new_record.user = new_generated_user
          else
            new_record.user = new_user
          end
          if new_committer.nil?
            new_generated_committer = User.new(kerberos_login: 'generated',
                                               cvs_username: item['qa_contact'].gsub("@#{Rails.configuration.bugzilla_domain}", '').gsub('@sourcefire.com', ''),
                                               email: item['qa_contact'],
                                               password: 'password',
                                               password_confirmation: 'password',
                                               committer: 'true')

            new_generated_committer.roles = Role.where(role:"committer")
            new_generated_committer.save
            new_record.committer = new_generated_committer
          else
            new_record.committer = new_committer
          end
          unless new_attachments.empty?
            new_attachments['bugs'][bug_id.to_s].each do |attachment|
              new_attachment = Attachment.find_or_create_by(id: attachment['id']) do |new_attach_record|
                new_attach_record.id = attachment['id']
                new_attach_record.size = attachment['size']
                new_attach_record.bugzilla_attachment_id = attachment['bug_id']
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
              new_record.attachments << new_attachment
            end
          end
          new_record.research_notes ||= "THESIS:\n\nRESEARCH:\n\nDETECTION GUIDANCE:\n\nDETECTION BREAKDOWN:\n\nREFERENCES:\n"
          unless new_comments.empty?
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
                note = Note.create(id: c['id'],
                                   author: c['author'],
                                   comment: comment,
                                   bug_id: bug_id,
                                   note_type: note_type,
                                   created_at: creation_time)
                new_record.notes << note
              end
            end
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

  def self.check_permission(current_user, bugs)
    class_allowed = User.class_levels[current_user.class_level]
    bugs.reject { |b| Bug.classifications[b.classification] > class_allowed }
  end
end
