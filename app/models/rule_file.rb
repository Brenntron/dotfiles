class RuleFile
  attr_reader :relative_pathname

  class << self
    attr_reader :publish_lock_pid
  end

  def self.pwd_switch
    Rails.configuration.svn_pwd.present? ? "--password #{Rails.configuration.svn_pwd}" : nil
  end

  def self.log(message)
    Rails.logger.info "svn integration: #{message}"
  end

  # @return [Mutex] mutex to exclusively change publishing lock
  def self.publish_mutex
    @publish_mutex ||= Mutex.new
  end

  # lock publishing, so current thread is only thread doing a commit
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

  # unlock publishing, so other threads can log publishing
  # Threads other than the one which locked publishing can unlock it.
  # It is up to the developer (via writting the code) to only unlock it from the right thread.
  def self.publish_unlock
    publish_mutex.synchronize do
      @publish_lock_pid = nil
    end
  end

  #unlock on startup when this class file is loaded.
  publish_unlock

  # @return [Boolean] if publishing is currently locked by some thread
  def self.publish_locked?
    publish_mutex.synchronize do
      !@publish_lock_pid
    end
  end

  # @return [Pathname] path (possibly relative) to the snort directory synchronized with svn
  def self.synch_root
    @snort_path ||= Pathname.new('extras/snort')
  end

  # @return [Pathname] relative path name of the version control working directory to use for commits
  def self.working_root
    @svn_pathname ||= Pathname.new('extras/working')
  end

  # @param [Pathname, String] input file name, absolute or relative
  # @return [Pathname] the part of the file name relative to a working folder, the synchronized or working folder
  def self.relative_path_of(filepath)
    relative_path = Pathname.new(filepath)
    relative_path = relative_path.relative_path_from(Rails.root) if relative_path.absolute?
    relative_path = relative_path.relative_path_from(synch_root) if relative_path.to_s.starts_with?(synch_root.to_s)
    relative_path
  end

  # @return [Pathname] file path in the working folder for commits
  def self.working_pathname_of(pathname)
    Rails.root.join(working_root, relative_path_of(pathname))
  end

  # @return [Pathname] path (possibly relative) to the snort directory directory synchronized with svn
  def synch_pathname
    @synch_pathname ||= Rails.root.join(self.class.synch_root, relative_pathname)
  end

  # @return [Pathname] the path to the file in the working directory
  def working_pathname
    @working_pathname ||= self.class.working_pathname_of(relative_pathname)
  end

  # @param [String|Pathname] file path relative to a working folder
  def initialize(relative_pathname)
    @relative_pathname = relative_pathname
  end

  # @param [Array[Rule]] array of rules
  # @return [Array[RuleFile]] array of RuleFile objects for unique file
  def self.build(rules)
    Rule.where(id: rules).select(:gid, :filename, :rule_category_id)
        .group(:gid, :filename, :rule_category_id)
        .map { |rule_group| new(relative_path_of(rule_group.nonnil_pathname)) }
  end

  # @return [String] space separated list of relative file paths
  def self.working_file_list(rule_files)
    rule_files.map{|rule_file| rule_file.working_pathname.to_s}.join(' ')
  end

  # deletes the file in the working folder used for commits
  def remove_working_file
    FileUtils.remove_file(working_pathname) rescue nil
  end

  # gets file from svn prepared for later commit
  def checkout
    FileUtils.mkpath(working_pathname.dirname)
    remove_working_file
    `svn up #{self.class.pwd_switch} #{working_pathname}`
  end

  # run failsafe to update db if callback did not
  def self.synch_failsafe
    build(Rule.where(publish_status: Rule::PUBLISH_STATUS_PUBLISHING)).each do |rule_file|
      `svn up #{pwd_switch} #{rule_file.synch_pathname}`
      File.open(rule_file.synch_pathname, 'rt') do |file|
        file.each_line do |line|
          Rule.load_line(line)
        end
      end
    end
  end

  # Checks in a set of given rules.
  # param [Array[Rule]] array of rules.
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

      log("committing files #{working_file_list(rule_files)}")
      `cd #{working_root};svn #{pwd_switch} commit #{working_file_list(rule_files)} -m "committed from Analyst Console"`

      rule_files.each {|rule_file| rule_file.remove_file rescue nil }

      #any rules not set to synch by svn hook should go back to current.
    end

    true

  ensure
    if Rule.where(publish_status: Rule::PUBLISH_STATUS_PUBLISHING).exists?
      log("setting rules from publishing to current_edit")
      synch_failsafe rescue nil
      Rule.where(publish_status: Rule::PUBLISH_STATUS_PUBLISHING)
          .update_all(publish_status: Rule::PUBLISH_STATUS_CURRENT_EDIT)
    end
    log("exiting publishing")
    publish_unlock
  end
end
