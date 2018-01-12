class FalsePositive < ApplicationRecord
  has_many :false_positive_file_refs
  has_many :s3_urls, through: :false_positive_file_refs, source: :file_ref, source_type: S3Url

  def file_refs
    false_positive_file_refs.map {|link| link.file_ref}
  end

  def sids_array
    sid_strs = sid.gsub(/\s*/, '').split(/[,;]/)
    sid_strs.map do |str|
      if /([1,3][-:])?(?<sid>\d{1,6})/ =~ str
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
  # @param [Bugzilla::Bug] bug_factory proxy interface to bugzilla.
  def create_bug(bug_factory)
    # @param [Bugzilla::XMLRPC] bugzilla_session proxy interface to bugzilla.

    bug_attrs = {
        'product' => 'Research',
        'component' => component,
        'summary' => summary,
        'version' => 'No Version Specified', #self.version,
        'description' => full_description,
        # 'opsys' => self.os,
        'priority' => 'Unspecified',
        'classification' => 'unclassified',
    }

    bug = Bug.bugzilla_create(bug_factory, bug_attrs, user: nil)
    # bug = nil
    update(bug_id: bug.id) if bug
    bug
  end

  # Create a bug in bugzilla, save it with an active record model, and post to the bug create channel
  # @param [Bugzilla::XMLRPC Token] bugzilla_session proxy interface to bugzilla.
  def create_bug_action(bugzilla_session)
    bug_factory = Bugzilla::Bug.new(bugzilla_session)

    bug = create_bug(bug_factory)

    conn = PeakeBridge::FpCreatedEvent.new(addressee: self.source_authority,
                                           source_authority: self.source_authority)
    conn.post(false_positive_id: self.id,
              bug_id: bug&.id,
              source_key: self.source_key)
    # Rails.logger.debug("PeakeBridge response.body = #{response.body.inspect}")

    bug
  rescue => except
    Rails.logger.error(except.message)
  end

  def save_attachments_from_params(attachments_attrs:)
    attachments_attrs.each do |s3_params|
      s3 = S3Url.create!(s3_params.permit("file_name", "url", "file_type_name"))
      false_positive_file_refs.create(file_ref: s3)
    end

    self
  end

  def self.create_from_params(attrs, attachments_attrs:, sender:)
    if where(source_authority: sender, source_key: attrs['source_key']).exists?
      where(source_authority: sender, source_key: attrs['source_key']).delete_all
    end
    create(attrs.merge(source_authority: sender)).tap do |false_positive|
      false_positive.save_attachments_from_params(attachments_attrs: attachments_attrs)
    end
  end
end
