class Bug < ActiveRecord::Base
  has_many :attachments, :dependent => :destroy
  has_many :exploits, :through => :references
  has_many :jobs, :dependent => :destroy

  has_and_belongs_to_many :references

  belongs_to :user
  belongs_to :committer, :class_name => 'User'


  def get_state(status, resolution)
    bug_state = "OPEN"
    if status != 'RESOLVED'
      bug_state = "OPEN"
    else
      if resolution.blank?
        bug_state = "OPEN"
      else
        bug_state = resolution
      end
    end
    bug_state
  end

  private

  def add_attachment(xmlrpc, file)
    Bugzilla::Bug.new(xmlrpc).attach_file(self.bugzilla_id, file)
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


  def self.import(new_bugs)
    new_bugs['bugs'].each do |item|
      Bug.find_or_create_by(bugzilla_id: item['id']) do |new_record|
        new_record.id        = item['id']
        new_record.state     = new_record.get_state(item['status'], item['resolution'])
        new_record.summary   = item['summary']
        new_record.creator   = User.where("email=?", item['creator']).first
        new_record.user      = User.where("email=?", item['assigned_to']).first
        new_record.committer = User.where("email=?", item['qa_contact']).first
        unless new_record.creator
          User.create(cvs_username: item['creator'].gsub("@#{Rails.configuration.bugzilla_domain}",""), email: item['creator'] ,password: 'password', password_confirmation: 'password',committer:'false')
        end
        unless new_record.user
          User.create(cvs_username: item['assigned_to'].gsub("@#{Rails.configuration.bugzilla_domain}",""), email: item['assigned_to'] ,password: 'password', password_confirmation: 'password',committer:'false')
        end
        unless new_record.committer
          User.create(cvs_username: item['qa_contact'].gsub("@#{Rails.configuration.bugzilla_domain}",""), email: item['qa_contact'] ,password: 'password', password_confirmation: 'password',committer:'false')
        end
      end
    end
    return true
  end

  def self.get_latest()
    latest_bug_date = Bug.order("created_at").last
    return latest_bug_date.nil? ? Time.now : latest_bug_date.created_at
  end

  def close(xmlrpc, notes=nil)
    self.bug_state = "FIXED"

    if notes.nil?
      if self.committer_notes.nil? or self.committer_notes == ''
        notes = 'Closing bug'
      else
        notes = self.committer_notes
      end
    end

    self.update_status(xmlrpc, 'resolved', 'fixed', notes)
    self.refresh_summary(xmlrpc)
    self.bugzilla_summary_sids_replace(xmlrpc, self.summary_sids)
    self.update_qa_contact(xmlrpc)
    self.update_summary(xmlrpc, self.summary.gsub(/\s*\[FP\]\s*/, '')) # Remove FP tags
    self.refresh_summary(xmlrpc)
  end


  def summary_sids
    sids = []

    unless self.summary.nil?
      self.summary.scan(/\[SID\]\s*?([\d\s,\-]+)(?:\s)?/).each do |match|
        match[0].split(/[,\s]/).each do |part|
          if part =~ /(\d+)-(\d+)/
            sids << eval("#{$1}..#{$2}").to_a
          else
            sids << part.gsub(/\s+/, '').to_i
          end
        end
      end
    end

    return sids.flatten.sort.uniq.delete_if {|a| a <= 0}
  end


  def publish

  end

end