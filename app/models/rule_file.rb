class RuleFile
  class << self
    attr_reader :publish_lock_pid
  end

  def self.log(message)
    Rails.logger.info "svn integration: #{message}"
  end

  def self.publish_mutex
    @publish_mutex ||= Mutex.new
  end

  def self.publish_lock
    publish_mutex.synchronize do
      if @publish_lock_pid
        nil
      else
        @publish_lock_pid = Process.pid
        true
      end
    end
  end

  def self.publish_unlock
    publish_mutex.synchronize do
      @publish_lock_pid = nil
    end
  end

  #unlock on startup when class file is loaded.
  publish_unlock

  def self.publish_locked?
    publish_mutex.synchronize do
      !@publish_lock_pid
    end
  end

  # Checks in a set of given rules.
  # param [Array[Integer]] Integer array of Rule model ids.
  def self.commit_rules_action(rules)
    rules.reject! { |rule| rule.synched? || rule.stale_edit? }

    if rules.any? && publish_lock
      log("publishing #{rules.count} rules")
      #set all the rules we will update to publishing.
      Rule.where(id: rules).update_all(publish_status: Rule::PUBLISH_STATUS_PUBLISHING)

      working_pathnames = Rule.checkout(rules)

      rules.each do |rule|
        rule.patch_file(rule.working_pathname)
      end

      `cd #{Rule.working_root};svn commit #{working_pathnames.join(' ')} -m "committed from Analyst Console"`
      # byebug

      #any rules not set to synch by svn hook should go back to current.
    end

    true

  ensure
    log("setting rules from publishing to current_edit")
    Rule.where(publish_status: Rule::PUBLISH_STATUS_PUBLISHING)
        .update_all(publish_status: Rule::PUBLISH_STATUS_CURRENT_EDIT)
    publish_unlock
  end
end
