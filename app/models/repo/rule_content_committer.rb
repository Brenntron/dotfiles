module Repo
  # class RuleContentCommitter handles committing the rule content.
  class RuleContentCommitter
    include Enumerable

    attr_reader :success, :rule_files, :rules, :changed_rules, :unchanged_rules, :bug, :user, :username

    # @return [Pathname] path (possibly relative) to the snort directory synchronized with svn
    def self.synch_root
      @snort_path ||= Pathname.new('extras/snort')
    end

    # @return [Pathname] relative path name of the version control working directory to use for commits
    def self.working_root
      @svn_pathname ||= Pathname.new('extras/working')
    end

    def self.ruledocs_root
      @svn_pathname ||= Pathname.new('extras/ruledocs')
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

    def self.collect_rule_files(rules)
      Rule.where(id: rules).select(:gid, :filename, :rule_category_id)
          .group(:gid, :filename, :rule_category_id)
          .map { |rule_group| ::RuleFile.new(relative_path_of(rule_group.nonnil_pathname)) }.tap do |rule_files|

        rule_files.each { |rule_file| Repo::RuleCommitter.log("*** Rule file path #{rule_file.relative_pathname}") }

        rules.each do |rule|
          rule_file = rule_files.detect do |rule_file|
            relative_path_of(rule.nonnil_pathname) == rule_file.relative_pathname
          end
          rule_file << rule if rule_file
        end

        rule_files.select! { |rule_file| 0 < rule_file.count }
      end
    end

    def initialize(rules, bugzilla_id: nil, user: nil, username: nil)
      @success = false
      @bug = bugzilla_id ? Bug.where(bugzilla_id: bugzilla_id).first : nil
      @user = user
      @username = username || user.cvs_username
      @rules = rules
      @changed_rules, @unchanged_rules = rules.partition { |rule| rule.content_changed? }

      @rule_files = self.class.collect_rule_files(@changed_rules)
    end

    def each(&block)
      rule_files.each(&block)
    end

    def log(message)
      Repo::RuleCommitter.log(message)
    end

    def call_svn(svn_args)
      Repo::RuleCommitter.call_svn(svn_args)
    end

    def svn_commit_message(rules)
      user_prefix = username ? "#{username} " : ''
      "#{user_prefix}committed #{rules.count} rule(s) from Analyst Console"
    end

    def svn_cmd
      pwd_switch = Rails.configuration.svn_pwd.present? ? "--password #{Rails.configuration.svn_pwd}" : nil
      "#{Rails.configuration.svn_cmd} #{pwd_switch}"
    end

    # @return [String] space separated list of relative file paths
    def working_file_list(rule_files)
      map{|rule_file| rule_file.working_pathname.to_s}.join(' ')
    end

    # Checks conditions which may prohibit a commit.
    # @param [Array[Rule]] rules collection of rules to check
    # @param [Boolean] nodoc_override true if should skip check for complete doc
    # @raise [RuntimeError] an exception if commit is prohibited.
    def self.prescreen!(rules, user, bug:, nodoc_override: false)

      raise "unknown user" unless user
      raise 'Some of those rules are unchanged!' if rules.any? {|rule| rule.synched?}
      raise 'Some of those rules cannot be committed because they have changed!' if rules.any? {|rule| rule.stale_edit?}
      raise "Cannot commit with untested rules!" unless rules.all? {|rule| rule.tested_on_bug?(bug) || rule.content_same?}
      raise "Cannot commit with incomplete rule docs!" unless nodoc_override || rules.all? { |rule| rule.doc_complete? }

    end

    # deletes the file in the working folder used for commits
    def remove_working_file(working_pathname)
      log("removing #{working_pathname}")
      FileUtils.remove_file(working_pathname) rescue nil
    end

    # gets file from svn prepared for later commit
    def checkout(relative_pathname)
      working_pathname = self.class.working_pathname_of(relative_pathname)
      working_dir = working_pathname.dirname

      unless File.directory?(working_dir)
        FileUtils.mkpath(working_dir)
        svn_url = "#{Rails.configuration.rules_repo_url}/#{relative_pathname.dirname}/"
        call_svn("co --depth empty #{svn_url} #{working_dir}")
      end

      remove_working_file(working_pathname)
      call_svn("up #{working_pathname}")
    end

    def commit_rule_files
      working_file_list = working_file_list(rule_files)
      Rails.logger.info("svn integration: committing files #{working_file_list}")

      svn_result_output = call_svn(%Q~commit #{working_file_list} -m "#{svn_commit_message(changed_rules)}"~)
      svn_result_code = if /\(exit code (?<svn_result_code_str>\d*)\)/ =~ svn_result_output
                          svn_result_code_str.to_i
                        end

      if bug
        changed_rules.each do |rule|
          rule.bugs_rules.where(bug_id: bug)
              .update_all(svn_result_output: svn_result_output, svn_result_code: svn_result_code || 0)
        end
      end

      Rails.logger.info("svn integration: content commit return code #{svn_result_code.inspect}")
      @success = (BugsRule::SVN_SUCCESS_COMMIT_HOOK == svn_result_code ? true : false)
      svn_result_output
    end

    # Commits the rule content of its collection of rule files and rules.
    def commit_rule_content
      log("publishing content #{rules.count} rules, #{rule_files.count} files")

      rule_files.each {|rule_file| checkout(rule_file.relative_pathname) }
      rule_files.each {|rule_file| rule_file.patch_file}
      commit_rule_files.tap do
        if success
          rule_files.each {|rule_file| remove_working_file(rule_file.working_pathname) rescue nil }
          rule_files.each {|rule_file| rule_file.load_add_line(bug.bugzilla_id) } if bug
        end
      end
    end
  end
end
