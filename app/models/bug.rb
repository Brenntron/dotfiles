class Bug < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  has_and_belongs_to_many :rules
  has_and_belongs_to_many :tags, dependent: :destroy
  belongs_to :user
  belongs_to :committer, :class_name => 'User'

  has_many :references, :dependent => :destroy
  has_many :exploits, :through => :references
  has_many :attachments, :dependent => :destroy
  has_many :tasks, :dependent => :destroy
  has_many :notes, :dependent => :destroy

  accepts_nested_attributes_for :references
  accepts_nested_attributes_for :rules

  scope :open, -> {where('state in (?)', ['OPEN', 'ASSIGNED', 'REOPENED'])}
  scope :closed, -> {where('state in (?)', ['FIXED', 'WONTFIX', 'LATER', 'INVALID', 'DUPLICATE'])}
  scope :pending, -> {where(state: "PENDING")}

  enum classification: {
      unclassified: 0,
      confidential: 1,
      secret: 2,
      top_secret: 3,
      top_secret_sci: 4
  }

  #after_create { |bug| bug.record 'create' if Rails.configuration.websockets_enabled == "true" }
  #after_update { |bug| bug.record 'update' if Rails.configuration.websockets_enabled == "true" }
  #after_destroy { |bug| bug.record 'destroy' if Rails.configuration.websockets_enabled == "true" }

  def record action
    obj = JSON.parse(BugSerializer.new(self).to_json)
    obj["bug"] = obj["bug"].except('notes', 'attachments', 'tasks', 'exploits')
    obj["bug"]["user"] = obj["bug"]["user_id"]
    record = {resource: 'bug',
              action: action,
              id: self.id,
              obj: obj.except("notes", "attachments", "rules", "references", "tasks", "exploits")}
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
      changed_bug = Bugzilla::Bug.new(xmlrpc).update(options) #the bugzilla session is where we authenticate
    end
    changed_bug
  end

  def self.bugs_with_search(params)
    if params[:bugzilla_max] == '' || params[:bugzilla_max].nil?
      query_params =params.reject{ |k, v| (v == "" || v.is_a?(Array) || k=='tag_name') }
      count = 0
      query = ''
      query_params.each do |k, v|
        count = count+1
        query = query + k + "='" + v.gsub("'", "\\'") + "'"
        query = query + " && " if count != query_params.count
      end
      Bug.where(query)
    end
  end

  def update_attachments(xmlrpc)
    fields = ['file_name', 'id', 'last_change_time', 'is_obsolete', 'size']

    # Now fetch the bug attachments and create them if needed
    xmlrpc.attachments(:ids => [self.bugzilla_id], :include_fields => fields)['bugs'][self.bugzilla_id.to_s].each do |attachment|

      next if attachment['file_name'] !~ /\.pcap$/
      attach = Attachment.find_by_bugzilla_attachment_id(attachment['id'])

      # We need to remove any obsoleted attachments
      if attachment['is_obsolete'] == 1
        if attach and attach.bug == self
          self.attachments.delete(attach)
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
            self.attachments << Attachment.create(
                :filename => attachment['file_name'],
                :bugzilla_attachment_id => attachment['id'],
                :file_size => attachment['size'])
          rescue ActiveRecord::RecordNotUnique => e
            # Ignore duplicate attempts
          end
        end
      end
    end
  end

  def self.update_state(bug, state, editor_email)
    updated_state = state
    updated_state = 'NEW' if editor_email == "vrt-incoming@sourcefire.com" && bug.resolution == 'OPEN'
    updated_state = 'ASSIGNED' unless (editor_email == 'vrt-incoming@sourcefire.com') || (%w(RESOLVED REOPENED).include? bug.status) || state == 'PENDING'
    updated_state = nil if updated_state == bug.state

    case updated_state
      when 'NEW'
        status = updated_state
        resolution = 'OPEN'
        comment = {comment: "This bug has been set back to NEW. #{bug.user.email} is no longer assigned to this bug."}
      when 'ASSIGNED'
        status = updated_state
        resolution = 'OPEN'
        comment = {comment: "This bug is now ASSIGNED to #{editor_email}."}
        assigned_at = Time.now
      when 'PENDING'
        status = 'RESOLVED'
        resolution = updated_state
        comment = {comment: "This bug is now RESOLVED - #{updated_state}."}
        pending_at = Time.now
        if bug.state == 'REOPENED'
          rework_time = ((pending_at - bug.reopened_at)/86400).ceil
        else
          work_time = ((pending_at - bug.assigned_at)/86400).ceil
        end
      when 'FIXED', 'WONTFIX', 'INVALID', 'DUPLICATE', 'LATER'
        status = 'RESOLVED'
        resolution = updated_state
        comment = {comment: "This bug is now RESOLVED - #{updated_state}."}
        resolved_at = Time.now
        review_time = ((resolved_at - bug.pending_at)/86400).ceil
      when 'REOPENED'
        status = updated_state
        resolution = 'OPEN'
        comment = {comment: "This bug is now #{updated_state}."}
        reopened_at = Time.now
    end

    state_params = {
        :state => updated_state,
        :status => status,
        :resolution => resolution,
        :comment => comment,
        :assigned_at => assigned_at,
        :pending_at => pending_at,
        :resolved_at => resolved_at,
        :reopened_at => reopened_at,
        :work_time => work_time,
        :rework_time => rework_time,
        :review_time => review_time
    }

  end

  def priority_sort
    if self.priority.nil?
      self.priority = 'Unspecified'
    else
      self.priority
    end
  end

  def can_set_pending?
    self.exploits.each do |expl|
      if expl.attachment.nil?
        return false
      end
    end
      true
  end

  def allow_state_change?
    if !self.user.present? || !self.committer.present?
      return false
    end
    true
  end

  def parse_summary

    parsed_summary = {}
    parsed_summary[:tags] = self.summary_tags
    parsed_summary[:sids] = self.summary_sids
    parsed_summary[:refs] = self.summary_references
    parsed_summary
  end

  def summary_tags
    summary_tags = summary_tag_array.map{|s| s.delete "[]"}
    if summary_tags
      create_tags_from_summary(summary_tags)
      summary_tags.map{|tag| Tag.find_by_name(tag)}
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
    return sids.flatten.sort.uniq.delete_if { |a| a <= 0 }
  end

  def summary_references
    references = []
    ReferenceType.where.not(bugzilla_format: nil).each do |ref_type|
      self.summary.scan(/#{ref_type.bugzilla_format}/i).each do |match|
        references << Reference.where(reference_type_id: ref_type.id, reference_data: match[0]).first_or_create
      end
    end

    return references.uniq
  end

  def tag_array
    #array of tags for comparison
    tags.map{|t| "[#{t.name}]"}
  end

  def summary_tag_array
    #array of tags in summary for comparison
    summary_without_sids.scan(/\[.*?\]/)
  end

  def compose_summary
    if tag_array.try(:sort) != summary_tag_array.try(:sort)

      #extract summary_tag_string and replace with tag_string
      summary_string = "#{self.summary}"
      summary_tag_array.each{|st| summary_string.slice! st } if !summary_tag_array.nil?
      tag_array.reverse.each{|ta| summary_string.prepend(ta) }

      self.update(summary: summary_string)
    end
  end

  def resolution_time
    if resolved_at.present?
      ((resolved_at - created_at)/86400).ceil
    else
      0
    end
  end

  private

  def create_tags_from_summary(summary_tags)
    summary_tags.each do |tag|
      Tag.create(name: tag)
    end
  end


  def add_attachment(xmlrpc, file)
    Bugzilla::Bug.new(xmlrpc).attach_file(self.bugzilla_id, file)
  end

  def self.bugzilla_import(xmlrpc, new_bugs)
    unless new_bugs.empty?
      new_bugs['bugs'].each do |item|
        bug_id = item['id']
        new_attachments = xmlrpc.attachments({:ids => [bug_id]})
        new_comments = xmlrpc.comments(:ids => [bug_id])

        Bug.find_or_create_by(bugzilla_id: bug_id) do |new_record|
          new_record.id = bug_id
          new_record.summary = item['summary']
          new_record.classification = "unclassified"

          new_record.status = item['status']
          new_record.resolution = item['resolution']
          new_record.resolution = "OPEN" if new_record.resolution.empty?
          new_record.state = new_record.get_state(item['status'], item['resolution'], item['assigned_to'])
          new_record.priority = item['priority']

          new_record.created_at = item['creation_time'].to_time
          last_change_time = item['last_change_time'].to_time
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

          creator = User.where("email=?", item['creator']).first
          new_user = User.where("email=?", item['assigned_to']).first
          new_committer = User.where("email=?", item['qa_contact']).first
          if creator.nil?
            new_record.creator = User.create(kerberos_login: "generated", cvs_username: item['creator'].gsub("@#{Rails.configuration.bugzilla_domain}", "").gsub("@sourcefire.com", ""), email: item['creator'], password: 'password', password_confirmation: 'password', committer: 'false')
          else
            new_record.creator = creator
          end
          if new_user.nil?
            new_record.user = User.create(kerberos_login: "generated", cvs_username: item['assigned_to'].gsub("@#{Rails.configuration.bugzilla_domain}", "").gsub("@sourcefire.com", ""), email: item['assigned_to'], password: 'password', password_confirmation: 'password', committer: 'false')
          else
            new_record.user = new_user
          end
          if new_committer.nil?
            new_record.committer = User.create(kerberos_login: "generated", cvs_username: item['qa_contact'].gsub("@#{Rails.configuration.bugzilla_domain}", "").gsub("@sourcefire.com", ""), email: item['qa_contact'], password: 'password', password_confirmation: 'password', committer: 'false')
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
                note = Note.create(:id => c['id'], :author => c['author'], :comment => comment, :bug_id => bug_id, :note_type => note_type, :created_at => creation_time)
                new_record.notes << note
              end
            end
          end
        end
      end
    end
    return true
  end

  def self.get_latest()
    latest_bug_date = Bug.order("created_at").last
  end

  def self.get_last_import_all()
    #this needs a manifest file to check against should the job fail half way through
    latest_bug_date = Event.where(action: "import_all").last
    return latest_bug_date.nil? ? Time.now-(1.day) : latest_bug_date.created_at
  end


  def bug_state(xmlrpc, notes=nil, status, resolution)
    deps = self.open_dependencies(xmlrpc)
    if deps.size > 0
      return {error: "This bug currently has open dependencies: #{deps}"}
    else
      self.bug_state = resolution
      if notes.nil?
        if self.committer_notes.nil? or self.committer_notes == ''
          notes = 'Closing bug'
        else
          notes = self.committer_notes
        end
      end

      committer_note = Note.create(comment: notes, note_type: "committer", author: current_user.email)
      self.notes << committer_note

      options = {:ids => [self.bugzilla_id], :status => status, :resolution => resolution, :comment => {:body => notes}}
      self.update_bugzilla_attributes(xmlrpc, options)
      self.refresh_summary(xmlrpc)
      self.bugzilla_summary_sids_replace(xmlrpc, self.summary_sids)
      options = {:ids => [self.bugzilla_id], :qa_contact => (self.committer.username)}
      self.update_bugzilla_attributes(xmlrpc, options)
      options = {:ids => [self.bugzilla_id], :summary => self.summary.gsub(/\s*\[FP\]\s*/, '')} # Remove FP tags
      self.update_bugzilla_attributes(xmlrpc, options)
      self.refresh_summary(xmlrpc)

      true
    end
  end

  def refresh_summary(xmlrpc)
    unless xmlrpc.nil?
      bug = Bugzilla::Bug.new(xmlrpc).get(self.bugzilla_id)['bugs'].first
      raise Exception.new("Unable to find bug #{record.bugzilla_id}") if bug.nil?
      self.summary = bug['summary']
    end
  end

  def update_bugzilla_attributes(xmlrpc, options)
    unless xmlrpc.nil?
      Bugzilla::Bug.new(xmlrpc).update(options)
    end
  end

  def bugzilla_summary_sids_add(xmlrpc, sids)
    unless xmlrpc.nil?
      # Make sure to get the latest summary
      self.refresh_summary(xmlrpc)
      # Now extract the existing sids
      self.bugzilla_summary_sids_replace(xmlrpc, (self.summary_sids + sids).flatten.compact)
    end
  end

  def bugzilla_summary_sids_replace(xmlrpc, sids)
    unless xmlrpc.nil?
      sids.delete_if { |sid| sid.zero? }
      unless sids.nil? or sids.empty?
        self.summary = "[SID] #{sids.to_ranges_compact_string} #{self.summary_without_sids}"
      end
      options = {:ids => [self.bugzilla_id], :summary => self.summary}
      Bugzilla::Bug.new(xmlrpc).update(options)
    end
  end

  def summary_without_sids
    self.summary.gsub(/\[SID\]\s*?([\d\s,\-]+)(?:\s)?/, '')
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
    raise Exception.new("Bugzilla xmlrpc session must be specified") if xmlrpc.nil?
    bug = Bugzilla::Bug.new(xmlrpc).get(self.bugzilla_id)['bugs'].first
    raise Exception.new("Unable to find bug #{record.bugzilla_id}") if bug.nil?
    return bug['depends_on']
  end

  def self.search(query_str, terms, range)
    bugs = Bug.where(summary: query_str) | Bug.where(bugzilla_id: range[:gte]...range[:lte]) | Bug.where(terms.symbolize_keys!)
  end

  def self.check_permission(current_user, bugs)
    class_allowed = User.class_levels[current_user.class_level]
    bugs.reject { |b| Bug.classifications[b.classification] > class_allowed }
  end

  settings index: {number_of_shards: 5} do
    mappings dynamic: 'false' do
      indexes :bugzilla_id, type: :integer
      indexes :user_id, type: :integer
      indexes :committer_id, type: :integer
      indexes :summary, type: :string, analyzer: :keyword
      indexes :state, type: :string, index: :not_analyzed
    end
  end
end