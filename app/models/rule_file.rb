class RuleFile
  attr_reader :relative_pathname

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

  # @return [Pathname] path (possibly relative) to the snort directory
  def self.synch_pathname
    @snort_path ||= Pathname.new('extras/snort')
  end

  # @return [Pathname] relative path name of the version control working directory
  def self.working_root
    @svn_pathname ||= Pathname.new('extras/working')
  end

  # @param [Pathname, String] input file name, absolute or relative
  def self.relative_path_of(filepath)
    relative_path = Pathname.new(filepath)
    relative_path = relative_path.relative_path_from(Rails.root) if relative_path.absolute?
    relative_path = relative_path.relative_path_from(synch_pathname) if relative_path.to_s.starts_with?(synch_pathname.to_s)
    relative_path
  end

  def self.working_pathname_of(pathname)
    Rails.root.join(working_root, relative_path_of(pathname))
  end

  # @return [Pathname] path (possibly relative) to the snort directory
  def synch_pathname
    @synch_pathname ||= Rails.root.join(self.class.synch_pathname, relative_pathname)
  end

  # @return [Pathname] the path to the file in the working directory
  def working_pathname
    @working_pathname ||= self.class.working_pathname_of(relative_pathname)
  end

  def initialize(relative_pathname)
    @relative_pathname = relative_pathname
  end

  def self.build(rules)
    Rule.where(id: rules).select(:gid, :filename, :rule_category_id)
        .group(:gid, :filename, :rule_category_id)
        .map { |rule_group| new(relative_path_of(rule_group.nonnil_pathname)) }
  end

  def self.working_file_list(rule_files)
    rule_files.map{|rule_file| rule_file.working_pathname.to_s}.join(' ')
  end

  def remove_file
    FileUtils.remove_file(working_pathname) rescue nil
  end

  def checkout
    FileUtils.mkpath(working_pathname.dirname)
    remove_file
    `cd #{self.class.working_root}; svn up #{working_pathname}`
  end

  # Checks in a set of given rules.
  # param [Array[Integer]] Integer array of Rule model ids.
  def self.commit_rules_action(rules)
    rules.reject! { |rule| rule.synched? || rule.stale_edit? }
    if rules.any? && publish_lock
      rule_files = build(rules)
      log("publishing #{rules.count} rules, #{rule_files.count} files")

      #set all the rules we will update to publishing.
      Rule.where(id: rules).update_all(publish_status: Rule::PUBLISH_STATUS_PUBLISHING)

      rule_files.each {|rule_file| rule_file.checkout }

      rules.each do |rule|
        rule.patch_file(working_pathname_of(rule.nonnil_pathname))
      end
      binding.pry

      log("committing files #{working_file_list(rule_files)}")
      `cd #{working_root};svn commit #{working_file_list(rule_files)} -m "committed from Analyst Console"`

      rule_files.each {|rule_file| rule_file.remove_file }

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
