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

  scope :any_relations, -> {
    left_joins(:rules).left_joins(:attachments).group(:id)
        .select('tasks.*, count(rules.id) as any_rules, count(attachments.id) as any_attachments')
  }

  scope :reverse_chron, -> {
    order("created_at desc")
  }

  TASK_TYPE_PCAP_TEST                   = "all rules test"
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

  def check_timeout
    if (Time.now - self.created_at) > 10.minutes  && self.completed.blank?
      self.failed = true
      self.result = "Task timed-out.  Possible poller down or network error."
      save
    end
  end

  def set_rule_tested
    BugsRule.joins(rule: :test_reports).where(test_reports: {task_id: self}).where(bug_id: bug_id)
        .update_all(tested: true)
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


  def run_rake(task_name,current_user,bugzilla_session)
    load File.join(Rails.root, 'lib', 'tasks', 'admin_rake_tasks.rake')
    Rake::Task[task_name].invoke(id, current_user, bugzilla_session, Rails.env)
    Rake::Task[task_name].reenable
  end

end
