class Task < ApplicationRecord
  belongs_to :bug, optional: true
  belongs_to :user, optional: true
  has_many :rules
  has_many :attachments

  after_create { |task| task.record 'create' if Rails.configuration.websockets_enabled == 'true' }
  after_update { |task| task.record 'update' if Rails.configuration.websockets_enabled == 'true' }
  after_destroy { |task| task.record 'destroy' if Rails.configuration.websockets_enabled == 'true' }

  def record(action)
    record = { resource: 'task',
               action: action,
               id: self.id,
               obj: self }
    PublishWebsocket.push_changes(record)
  end

  # Parsed output of results from testing rules
  def stats
    result.split("\n").inject({}) do |stats, line|
      line.lstrip!
      num, sid, gid, rev, checks, matches, alerts, microsecs, ave_check, ave_match, ave_nonmatch, disabled =
          line.split(/\s+/)
      if num =~ /^\d+$/
        stats[sid.to_i] = { average_check: ave_check, average_match: ave_match, average_nonmatch: ave_nonmatch }
      end

      stats
    end
  end

  # Set stats fields on rule records
  def update_rule_stats
    stats.each_pair do |sid, attrs|
      rule = Rule.by_sid(sid).first
      if rule && rule.sid
        rule.update(attrs)
      end
    end

    true
  end
end
