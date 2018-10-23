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

    # @return [String] space separated list of relative file paths
    def working_file_list(rule_files)
      map{|rule_file| rule_file.working_pathname.to_s}.join(' ')
    end

    # Checks conditions which may prohibit a commit.
    # @param [Array[Rule]] rules collection of rules to check
    # @param [Boolean] nodoc_override true if should skip check for complete doc
    # @raise [RuntimeError] an exception if commit is prohibited.
    def self.prescreen!(rules, user, bug:, nodoc_override: false)

      raise "bug is in #{bug.liberty} state" unless bug.liberty_clear?
      raise 'unknown user' unless user
      raise 'Some of those rules are unchanged!' if rules.any? {|rule| rule.synched?}
      raise 'Some of those rules cannot be committed because they have changed in the repo!' if rules.any? {|rule| rule.stale_edit?}
      raise "Cannot commit with untested rules!" if ( (bug.pcaps.present?) && !(rules.all? {|rule| rule.tested_on_bug?(bug) || rule.content_same?}))

    end

    # deletes the file in the working folder used for commits
    def remove_working_file(working_pathname)
      log("removing #{working_pathname}")
      FileUtils.remove_file(working_pathname) rescue nil
    end

    def self.snort_dir
      @snort_dir ||= Rails.root.join('extras', 'snort')
    end

    def self.svn_diff_output(filepath)
      `#{Rails.configuration.svn_cmd} diff -r PREV:BASE #{filepath}`
    end

    # Processes rule content from a subversion diff add line.
    #
    # Line should be qualified as an add from the diff which is a rule (with a sid).
    #
    # Compares rule to any matching new rules being published, and loads rule_content (e.g. the sid) onto that record.
    # If no matching new rule is found, then it is a new rule it needs to be added to the database.
    # If no matching new rule is found, it may be an edited rule, and should be loaded to a rule with the same sid.
    # @param [String] rule_content line added in a subversion diff, which should be a rule_content string.
    # @param [ActiveRecord::Relation] rules_rel collection of rules to match new rules to.
    # @param [Bug] bug A bug object to add new rules to.
    def self.repo_add_line(rule_content, rules_rel: Rule.all, bug: nil)
      # Get a parser to match the rule content to any new rules
      parser = RuleSyntax::NetSnortParser.new_from_rule_content(rule_content)
      unless parser
        Rails.logger.error("Net Snort Parser cannot parse rule_content = #{rule_content.chomp.inspect}")
        return false
      end

      # Looking only at new rules being published, find any that matches the rule content
      new_publishing_rules = rules_rel.where(edit_status: Rule::EDIT_STATUS_NEW).with_pub_content
      found_rules = new_publishing_rules.to_a.select do |rule|
        parsed_rule = RuleSyntax::NetSnortParser.new_from_rule_content(rule.rule_content)
        parser.match?(parsed_rule)
      end

      # If found, load the rule content, in particular the sid, onto that record.
      rule =
          case
            when 1 == found_rules.count
              # The rule matches a new rule in the collection of rules
              found_rule = found_rules.first
              found_rule.load_rule_content(rule_content, should_clear_svn_result: false)
              found_rule

            when 1 < found_rules.count
              # Do not create or update rule
              # If not found, load the rule content which will us any record that already had the sid,
              # or create a new rule.
              nil

            else
              # loaded_rule = Rule.find_and_load_rule_content(rule_content, should_clear_svn_result: false)
              # parser = RuleSyntax::RuleParser.new(rule_content)
              # rule = Rule.find_from_parser(parser)
              loaded_rule = Rule.synch_rule_content(rule_content)
              if bug
                bug.rules << loaded_rule unless loaded_rule.new_record? || bug.rules.where(id: loaded_rule.id).exists?
              end
              loaded_rule
          end

      if rule&.publishing_content?
        Rule.set_pubdoc_state(rule)
      end

      rule
    end

    def self.repo_notify_relative_filenames(relative_filenames)
      relative_filenames.each do |relative_filepath|

        # unless /(?<filename>[-\w]+\/[-\w]+\.rules)\s*$/ =~ filepath_given
        #   Rails.logger.error("Will not process #{filename.inspect}, skipping.")
        #   next
        # end

        filepath = snort_dir.join(relative_filepath)
        Rails.logger.debug("path #{filepath.inspect}")

        unless File.directory?(filepath.dirname)
          Rails.logger.error("SVN NOTIFY: No directory #{filepath.dirname}")
          next
        end

        svn_diff_output(relative_filepath).split("\n").each do |line|
          next if /^\+\+\+/ =~ line
          next unless /sid:\s*\d+\s*;/ =~ line

          if /^\+(?<add_line>.*)$/ =~ line.chomp
            repo_add_line(add_line)
          end
        end
      end
    end

    def self.repo_notify_given_filenames(given_filenames)
      relative_filenames = given_filenames.map do |filepath_given|
        if /(?<filename>[-\w]+\/[-\w]+\.rules)\s*$/ =~ filepath_given
          filename
        else
          Rails.logger.error("Will not process #{filename.inspect}, skipping.")
          nil
        end
      end.compact

      svn_up(relative_filenames)
      repo_notify_relative_filenames(relative_filenames)
    end

    def self.svn_up(relative_filenames)
      Rails.logger.info("svn up #{relative_filenames.join(" ")}")
      # Rails.logger.debug "cd #{snort_dir}\\;svn up #{relative_filenames.join(' ')}"
      `cd #{snort_dir}\\;svn up #{relative_filenames.join(' ')}`
      Rails.logger.info("notify svn up is done")
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

    def check_rev(rule)
      return if rule.new_rule?
      rule_grep_line = Rule.grep_line_from_file!(rule.sid, rule.gid, rule.filename)
      filename, line_number, rule_content = rule_grep_line.partition(/:\d+:/)
      unless rule.rev_matches?(rule_content)
        rule.update(publish_status: Rule::PUBLISH_STATUS_STALE_EDIT, state: Rule::STALE_STATE)
      end
    end

    def check_all_revs
      changed_rules.each {|rule| check_rev(rule)}
      raise 'Cannot commit; revisions do not match the repo' if changed_rules.any?{ |rule| rule.stale_edit? }
    end

    def call_commit
      working_file_list = working_file_list(rule_files)
      Rails.logger.info("svn integration: committing files #{working_file_list}")

      call_svn(%Q~commit #{working_file_list} -m "#{svn_commit_message(changed_rules)}"~)
    end

    def commit_rule_files
      svn_result_output = call_commit
      svn_result_code = if /\(exit code (?<svn_result_code_str>\d*)\)/ =~ svn_result_output
                          svn_result_code_str.to_i
                        end
      @success = (Rule::SVN_SUCCESS_COMMIT_HOOK == svn_result_code ? true : false)

      changed_rules.each do |rule|
        rule.update(svn_result_output: svn_result_output,
                    svn_result_code: svn_result_code || 0,
                    svn_success: @success)
      end

      additional_output = rule_files.map {|rule_file| rule_file.build_additional_output}.join("\n")
      svn_result_output = svn_result_output + additional_output

      Rails.logger.info("svn integration: content commit return code #{svn_result_code.inspect}")
      svn_result_output
    end

    # Commits the rule content of its collection of rule files and rules.
    def commit_rule_content
      log("publishing content #{rules.count} rules, #{rule_files.count} files")

      rule_files.each {|rule_file| checkout(rule_file.relative_pathname) }
      check_all_revs
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
