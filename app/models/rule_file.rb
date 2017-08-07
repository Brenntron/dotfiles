# class RuleFile
# This is a class for a rules file representing one *.rules file.
#
# This object has the file path of the *.rules file,
# and a collection of rules which are a subset of rules which belong in the rule.
# The object has self knowledge of how to update the file with rule content.
#
# TODO: Move the commit code to a committer object.
# TODO: Move the code not involved in committing to the RuleSyntax module.
# TODO: Merge this class after removing the committer code, with the RuleSyntax::RuleExporter class.
class RuleFile
  include Enumerable

  attr_reader :relative_pathname, :rules

  class << self
    attr_reader :publish_lock_pid
  end

  def to_s
    relative_pathname.to_s
  end

  def <<(rule)
    rules << rule
  end

  def each(&block)
    rules.each(&block)
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
    log("publish lock")
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
    log("publish unlock")
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
    @rules = []
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

  def patch_file
    rules.each do |rule|
      rule.patch_file(self.class.working_pathname_of(rule.nonnil_pathname))
    end
  end

  # deletes the file in the working folder used for commits
  def remove_working_file
    FileUtils.remove_file(working_pathname) rescue nil
  end

  # gets file from svn prepared for later commit
  def checkout
    unless File.directory?(working_pathname.dirname)
      FileUtils.mkpath(working_pathname.dirname)
      svn_url = "#{Rails.configuration.rules_repo_url}/#{relative_pathname.dirname}/"
      self.class.log("svn co --depth empty #{svn_url} #{working_pathname.dirname}")
      `#{self.class.svn_cmd} co --depth empty #{svn_url} #{working_pathname.dirname}`
    end

    remove_working_file
    self.class.log("svn up #{working_pathname}")
    `#{self.class.svn_cmd} up #{working_pathname}`
  end

  # links a new rule to the bug
  # calling code should check that this rule is not already a rule associated with this bug.
  def link_add_line_rule(bug, rule_content)
    parser = RuleSyntax::RuleParser.new(rule_content)
    msg = parser.attributes[:msg]
    found_rule = bug.rules.where(edit_status: Rule::EDIT_STATUS_NEW).with_pub_content.where(message: msg).first

    if found_rule
      found_rule.load_rule_content(rule_content, should_clear_svn_result: false)
      Rule.set_pubdoc_state(found_rule)
      found_rule
    else
      loaded_rule = Rule.find_and_load_rule_content(rule_content, should_clear_svn_result: false)
      bug.rules << loaded_rule unless loaded_rule.new_record? || bug.rules.pluck(:id).include?(loaded_rule.id)
      Rule.set_pubdoc_state(loaded_rule)
      loaded_rule
    end
  end

  # read diffs from file to add new rules to bug
  def load_add_line(bugzilla_id)
    bug = Bug.where(bugzilla_id: bugzilla_id).first
    `#{self.class.svn_cmd} up #{synch_pathname}`
    `#{self.class.svn_cmd} diff -r PREV:BASE #{synch_pathname}`.each_line do |line|
      if (/^\+/ =~ line) && (/^\+\+\+/ !~ line) && (/sid:\s*\d+\s*;/ =~ line)
        link_add_line_rule(bug, line[1..-1])
      end
    end
  end

  def synch_failsafe
    unless File.directory?(synch_pathname.dirname)
      FileUtils.mkpath(synch_pathname.dirname)
      svn_url = "#{Rails.configuration.rules_repo_url}/#{relative_pathname.dirname}/"
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
    committer = Repo::RuleCommitter.new(Rule.with_pub_content)
    committer.rule_files.each do |rule_file|
      rule_file.synch_failsafe
    end
  end

  # Rule committing code when the publish is locked
  # param [Array[Rule]] rules_given array of rules.
  # param [Repo::RuleContentCommitter] content_committer The committer object.
  # TODO: move to RuleCommitter class.
  # TODO: aggregate Repo::RuleContentCommitter object instead of passing to this method
  def self.locked_commit(rules_given, user:, username:, bugzilla_id:, content_committer:)
    if publish_lock
      committer = Repo::RuleCommitter.new(rules_given, bugzilla_id: bugzilla_id, user: user, username: username)
      committer.event_start

      rules = committer.changed_rules
      log("publishing #{rules.count} rules")

      if rules.any?
        rule_files = committer.rule_files
        log("publishing content #{rules.count} rules, #{rule_files.count} files")

        #set all the rules we will update to publishing.
        Rule.set_pubcontent_state(Rule.where(id: rules))

        content_committer.commit_rule_content

        # TODO: Move the code in RuleCommitter#commit_rule_content to RuleContentCommitter#commit_rule_content
        committer.commit_rule_content(bugzilla_id: bugzilla_id)

        if Rule.with_pub_content.exists?
          log("calling failsafe")
          synch_failsafe
        end
      end

      log("publishing rule docs for #{rules.count} rules")
      Rule.set_pubdoc_state(Rule.where(id: content_committer.unchanged_rules))

      committer.commit_docs

      log('returning a success')
      true
    end

  ensure
    #any rules not set to synch by svn hook should go back to current.
    if Rule.with_pub_any.exists?
      log("setting rules from publishing to current_edit")
      Rule.with_pub_any.update_all(publish_status: Rule::PUBLISH_STATUS_CURRENT_EDIT)
    end

    committer.event_complete if defined? committer

    log("unlocking publishing")
    publish_unlock
    log("exiting publishing")
  end

  # Handle the action from the API controller for committing rules.
  #
  # This method handles setup and cleanup around constructing the committer object and calling it.
  # Note that if it was merged with the method which does the work,
  # then there would be too much in the rescue and ensure sections.
  # That is a bad situation, because exceptions raised in the rescue and ensure sections
  # are not handled properly (or alternatively the code gets out of hand).
  #
  # param [Array[Rule]] rules array of rules.
  # param [String] username The username to add to the svn comment (message)
  # param [FixNum] bugzilla_id The bugzilla id of the bug
  # param [Boolean] nodoc_override true if commit should skip check prohibiting missing rule docs
  def self.commit_rules_action(rules, username:, bugzilla_id:, nodoc_override: false)
    user = User.where(cvs_username: username).first

    content_committer = Repo::RuleContentCommitter.new(rules, bugzilla_id: bugzilla_id, user: user, username: username)

    content_committer.prescreen!(nodoc_override: nodoc_override)

    locked_commit(rules, user: user, username: username, bugzilla_id: bugzilla_id, content_committer: content_committer)

  rescue
    Rails.logger.error $!
    Rails.logger.error $!.backtrace.join("\n")
    raise
  end
end
