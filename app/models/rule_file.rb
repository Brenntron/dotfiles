class RuleFile
  attr_reader :relative_pathname

  class << self
    attr_reader :publish_lock_pid
  end

  def to_s
    relative_pathname.to_s
  end

  def self.svn_cmd
    pwd_switch = Rails.configuration.svn_pwd.present? ? "--password #{Rails.configuration.svn_pwd}" : nil
    "#{Rails.configuration.svn_cmd} #{pwd_switch}"
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
    @relative_pathname = Pathname.new(relative_pathname)
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
    unless File.directory?(working_pathname.dirname)
      FileUtils.mkpath(working_pathname.dirname)
      svn_url = "https://repo-test.vrt.sourcefire.com/svn/rules/trunk/#{relative_pathname.dirname}/"
      `#{self.class.svn_cmd} co --depth empty #{svn_url} #{working_pathname.dirname}`
    end

    remove_working_file
    `#{self.class.svn_cmd} up #{working_pathname}`
  end

  # links a new rule to the bug
  # calling code should check that this rule is not already a rule associated with this bug.
  def link_new_rule(bug, rule)
    bug.rules << rule
    publishing_rule =
        bug.rules.where(publish_status: Rule::PUBLISH_STATUS_PUBLISHING).where(message: rule.message).first
    publishing_rule.bugs.delete_all if publishing_rule
  end

  # read diffs from file to add new rules to bug
  def load_add_line(bugzilla_id)
    bug = Bug.where(bugzilla_id: bugzilla_id).first
    `#{self.class.svn_cmd} up #{synch_pathname}`
    `#{self.class.svn_cmd} diff -r PREV:BASE #{synch_pathname}`.each_line do |line|
      if (/^\+/ =~ line) && (/^\+\+\+/ !~ line) && (/sid:\s*\d+\s*;/ =~ line)
        rule = Rule.find_and_load_rule_content(line[1..-1])
        link_new_rule(bug, rule) unless rule.new_record? || bug.rules.pluck(:id).include?(rule.id)
      end
    end
  end

  def synch_failsafe
    unless File.directory?(synch_pathname.dirname)
      FileUtils.mkpath(synch_pathname.dirname)
      svn_url = "https://repo-test.vrt.sourcefire.com/svn/rules/trunk/#{relative_pathname.dirname}/"
      `#{self.class.svn_cmd} co --depth files #{svn_url} #{synch_pathname.dirname}`
    end

    `#{self.class.svn_cmd} up #{synch_pathname}`
    File.open(synch_pathname, 'rt') do |file|
      file.each_line do |line|
        Rule.load_line(line)
      end
    end
  end

  # run failsafe to update db if callback did not
  def self.synch_failsafe
    build(Rule.where(publish_status: Rule::PUBLISH_STATUS_PUBLISHING)).each do |rule_file|
      rule_file.synch_failsafe
    end
  end

  # Checks in a set of given rules.
  # param [Array[Rule]] array of rules.
  def self.commit_rules_action(rules, username, bugzilla_id)
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
      `#{svn_cmd} commit #{working_file_list(rule_files)} -m "#{username} committed from Analyst Console"`

      rule_files.each {|rule_file| rule_file.remove_working_file rescue nil }

      rules.each do |rule|
        if rule.rule_doc
          rule.rule_doc.commit_doc(username)
          rule.update(publish_status: Rule::PUBLISH_STATUS_SYNCHED,
                      edit_status: Rule::EDIT_STATUS_SYNCHED,
                      state: 'UNCHANGED')
        end
      end

      rule_files.each {|rule_file| rule_file.load_add_line(bugzilla_id) } if bugzilla_id

      if Rule.where(publish_status: Rule::PUBLISH_STATUS_PUBLISHING).exists?
        synch_failsafe
      end
    end

    true

  ensure
    #any rules not set to synch by svn hook should go back to current.
    if Rule.where(publish_status: Rule::PUBLISH_STATUS_PUBLISHING).exists?
      log("setting rules from publishing to current_edit")
      Rule.where(publish_status: Rule::PUBLISH_STATUS_PUBLISHING)
          .update_all(publish_status: Rule::PUBLISH_STATUS_CURRENT_EDIT)
    end
    log("exiting publishing")
    publish_unlock
  end
end
