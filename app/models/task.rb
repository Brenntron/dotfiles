class Task < ApplicationRecord
  belongs_to :bug, optional: true
  belongs_to :user, optional: true
  has_many :test_reports
  has_many :rules, through: :test_reports
  has_many :attachments

  after_create { |task| task.record 'create' if Rails.configuration.websockets_enabled == 'true' }
  after_update { |task| task.record 'update' if Rails.configuration.websockets_enabled == 'true' }
  after_destroy { |task| task.record 'destroy' if Rails.configuration.websockets_enabled == 'true' }

  scope :latest_timestamp, -> {
    select('max(tasks.updated_at) as updated_at')
  }

  TASK_TYPE_PCAP_TEST                   = "pcap test"
  TASK_TYPE_LOCAL_TEST                  = "local test"

  def self.create_pcap_test(bug_id, user_id)
    create(
        :bug_id         => bug_id,
        :task_type      => TASK_TYPE_PCAP_TEST,
        :user_id        => user_id,
    )
  end

  def self.create_rule_test(bug_id, user_id)
    create(
        :bug_id         => bug_id,
        :task_type      => TASK_TYPE_LOCAL_TEST,
        :user_id        => user_id,
    )
  end

  def record(action)
    record = { resource: 'task',
               action: action,
               id: self.id,
               obj: self }
    PublishWebsocket.push_changes(record)
  end


  # Parsed output of results from testing rules
  def performance_stats
    result.each_line.map do |line|
      line.lstrip!
      num, sid, gid, rev, cks, mch, alt, micsec, ave_check, ave_match, ave_nonmatch, dis = line.split(/\s+/)
      if num =~ /^\d+$/
        { gid: gid.to_i, sid: sid.to_i,
          average_check: ave_check, average_match: ave_match, average_nonmatch: ave_nonmatch }
      else
        nil
      end
    end.select{ |elem| elem }
  end

  # For a local test, set rule performance stats on test_report records
  #
  # When doing a local test on a bug, performance stats on the top ten slowest rules are returned.
  # Keep these in the test_reports table.
  def update_rule_stats
    bug.test_reports.all.delete_all
    performance_stats.each do |stats|
      rule = Rule.by_sid(stats[:sid], stats[:gid]).first
      if rule
        data = stats.slice(*%i(average_check average_match average_nonmatch))
        test_reports.create(data.merge(rule_id: rule.id, bug_id: bug.id))
      end
    end

    update(stats_updated_at: Time.now)

    true
  end

  def test_attachments(options, xmlrpc_token)
    options[:attachment_array].split(',').each do |attachment_id|
      self.attachments << Attachment.where(id: attachment_id).first unless nil
    end
    TestAttachment.send_work_msg(self, xmlrpc_token, options[:attachment_array])
  end

  def test_rules(options, xmlrpc_token)
    options[:rule_array].split(',').each do |rule_id|
      self.rules << Rule.where(id: rule_id).first unless nil
    end
    TestRule.send_work_msg(self, xmlrpc_token, self.bug)
  end
end
