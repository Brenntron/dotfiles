class FalsePositive < ApplicationRecord
  has_many :fp_file_refs
  has_many :file_references, through: :fp_file_refs

  def sids_array
    sid_strs = sid.gsub(/\s*/, '').split(/[,;]/)
    sid_strs.map do |str|
      if /([1,3][-:])?(?<sid>\d{3,6})/ =~ str
        sid
      end
    end.compact
  end

  def component
    sid_strs = sid.gsub(/\s*/, '').split(/[,;]/)

    has_snort = false
    has_so = false
    sid_strs.each do |str|
      if /((?<gid>[1,3])[-:])?\d{1,6}/ =~ str
        has_snort = true if '1' == gid
        has_so    = true if '3' == gid
      end
    end
    case
      when has_snort
        'Snort Rules'
      when has_so
        'SO Rules'
      else
        'Snort Rules'
    end
  end

  def summary
    sidtag = sids_array.any? ? "[SID] #{sids_array.join(",")} " : ''
    "#{sidtag}False positive report from #{source_authority} at #{DateTime.now.utc.strftime("%Y-%m-%d %H:%M")}"
  end

  def full_description
    %Q{#{description}

### Metadata
Submitter: #{user_email}
SID: #{sid}
Source: #{source_authority}
OS: #{os}
Version: #{version}
Built From: #{built_from}
Command Line Options: #{cmd_line_options}
PCAP Utility: #{pcap_lib}
}
  end

  # Create a bug in bugzilla, save it with an active record model, and post to the bug create channel
  # @param [Bugzilla::XMLRPC] bugzilla_session proxy interface to bugzilla.
  def create_bug(bugzilla_session, user: nil)
    Rails.logger.info("started Creating a bug")
    bug_factory = Bugzilla::Bug.new(bugzilla_session)

    Rails.logger.info("bug_factory was created")
    bug_attrs = {
        'product' => 'Escalations',
        'component' => 'TAC',
        'summary' => summary,
        'version' => 'unspecified', #self.version,
        'description' => full_description,
        # 'opsys' => self.os,
        'priority' => 'Unspecified',
        'classification' => 'unclassified',
    }
    Rails.logger.info("bug_attrs are: #{bug_attrs}\n")
    bug = Bug.bugzilla_create(bug_factory, bug_attrs, user: user)
    Rails.logger.info("finished creating a buzilla bug. now updating")
    update(bug_id: bug.id) if bug
    Rails.logger.info("finished creating the bug")
    bug
  end

  def add_attachments(bug, bugzilla_session, user:)
    Rails.logger.info("Gathering attachments for bug #{bug.id}")
    fp_file_refs.each do |fp_file_ref|
      if fp_file_ref.file_reference.kind_of?(S3Url)
        s3_url = fp_file_ref.file_reference
        file = s3_url.get_file
        bug.add_attachment_action(bugzilla_session,
                                  file,
                                  user: user,
                                  filename: fp_file_ref.file_reference.file_name,
                                  content_type: 'application/octet-stream')
      end
    end
  rescue => except
    Rails.logger.error(except.message)
  end

  def post_fp_created(bug)
    Rails.logger.info("Sending Confirmation to #{self.source_authority}")
    conn = ::Bridge::FpCreatedEvent.new(addressee: self.source_authority, source_authority: self.source_authority)
    conn.post(false_positive_id: self.id, bug_id: bug&.id, source_key: self.source_key)
    Rails.logger.info("Confirmation to #{self.source_authority} sent successfully")
  end

  def save_attachments_from_params(attachments_attrs:)
    attachments_attrs.each do |s3_params|
      attrs = s3_params.permit("file_name", "location", "url", "file_type_name").to_h.clone
      location = attrs.delete('location')
      url = attrs.delete('url')
      attrs['location'] = S3Url.sanitize_location(location || url)
      attrs['source'] = self.source_authority
      s3_url = S3Url.create!(attrs)
      fp_file_refs.create(file_reference: s3_url)
    end

    self
  end

  def self.create_from_params(attrs, attachments_attrs:, sender:)
    Rails.logger.info("Creating False Positive from attributes")
    if where(source_authority: sender, source_key: attrs['source_key']).exists?
      where(source_authority: sender, source_key: attrs['source_key']).delete_all
    end
    create(attrs["fp_attrs"].merge(source_authority: sender, user_email:attrs["user_email"], source_key: attrs['source_key'])).tap do |false_positive|
      false_positive.save_attachments_from_params(attachments_attrs: attachments_attrs["attachments"])
    end
  end

  def import_bug(bugzilla_session, bugzilla_id, user:)
    Rails.logger.info("Importing information from bug #{bugzilla_id}")
    bug_stub = Bugzilla::Bug.new(bugzilla_session)
    bug_hash = bug_stub.get(bugzilla_id)
    Bug.bugzilla_import(user,
                        bug_stub,
                        bugzilla_session,
                        bug_hash)
  rescue => except
    Rails.logger.error(except.message)
  end

  # Create a bug in bugzilla, save it with an active record model, and post to the bug create channel
  # @param [Bugzilla::XMLRPC Token] bugzilla_session proxy interface to bugzilla.
  # @param [String] sender key for config.yml section for sources
  def create_escalation_action(bugzilla_session)
    Rails.logger.info("Creating Escalation")
    Rails.logger.info("Getting user bug")
    user = User.where(cvs_username:"vrtincom").first
    Rails.logger.info("Creating bug")
    bug = create_bug(bugzilla_session, user: user)
    Rails.logger.info("bug was created")
    if bug
      add_attachments(bug, bugzilla_session, user: user)
      import_bug(bugzilla_session, bug.bugzilla_id, user: user)
      post_fp_created(bug)
    end
    bug
  rescue => except
    Rails.logger.error(except.message)
  end
end
