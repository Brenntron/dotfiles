module Repo
  # class RuleCommitter handles committing rule content and rule docs.
  # Calls RuleContentCommitter class to commit the rule content.
  class RuleCommitter
    include Enumerable

    attr_reader :rule_files, :rules, :changed_rules, :unchanged_rules, :bug, :user, :username

    def log(message)
      Rails.logger.info "svn integration: #{message}"
    end

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

    def self.collect_rule_files(rules)
      Rule.where(id: rules).select(:gid, :filename, :rule_category_id)
          .group(:gid, :filename, :rule_category_id)
          .map { |rule_group| ::RuleFile.new(relative_path_of(rule_group.nonnil_pathname)) }.tap do |rule_files|

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
      @bug = bugzilla_id ? Bug.where(bugzilla_id: bugzilla_id).first : nil
      @user = user
      @username = username || user.cvs_username
      @rules = rules
      @changed_rules, @unchanged_rules = rules.partition { |rule| rule.content_changed? }

      @rule_files = self.class.collect_rule_files(@changed_rules)
    end

    def event_start
      @rule_commit_event = RuleEvent::RuleCommitEvent.start(bug.bugzilla_id, rules, user.id)
    end

    def event_success
      @rule_commit_event&.update(failed: false)
    end

    def event_complete
      @rule_commit_event&.update(completed: true)
    end

    def each(&block)
      rule_files.each(&block)
    end

    def svn_commit_message
      user_prefix = username ? "#{username} " : ''
      "#{user_prefix}committed from Analyst Console"
    end

    def svn_cmd
      pwd_switch = Rails.configuration.svn_pwd.present? ? "--password #{Rails.configuration.svn_pwd}" : nil
      "#{Rails.configuration.svn_cmd} #{pwd_switch}"
    end

    # @return [String] space separated list of relative file paths
    def working_file_list(rule_files)
      map{|rule_file| rule_file.working_pathname.to_s}.join(' ')
    end

    def commit_rule_files
      working_file_list = working_file_list(rule_files)
      log("committing files #{working_file_list}")

      svn_result_output = `#{svn_cmd} commit #{working_file_list} -m "#{svn_commit_message}" 2>&1`
      Rails.logger.info svn_result_output.gsub("\n", "~\n   ")
      svn_result_code = if /\(exit code (?<svn_result_code_str>\d*)\)/ =~ svn_result_output
                          svn_result_code_str.to_i
                        end

      if bug
        changed_rules.each do |rule|
          rule.bugs_rules.where(bug_id: bug)
              .update_all(svn_result_output: svn_result_output, svn_result_code: svn_result_code || 0)
        end
      end

      log("content commit return code #{svn_result_code.inspect}")
      raise "Rule content commit failed." unless 199 == svn_result_code
      svn_result_code
    end

    def commit_rule_content(bugzilla_id:)
      commit_rule_files

      rule_files.each {|rule_file| rule_file.remove_working_file rescue nil }

      rule_files.each {|rule_file| rule_file.load_add_line(bugzilla_id) } if bugzilla_id
    end

    def commit_doc?(rule)
      case
        when Rule::PUBLISH_STATUS_PUBLISHING == rule.publish_status
          false #rule content failed to commit
        when rule.requires_doc? && !rule.has_doc?
          Rule.set_synched_state(rule)
          false
        else
          true
      end
    end

    # TODO: Move commit_docs to its own class
    def commit_docs
      #refresh rule objects from database
      @rules = Rule.where(id: @rules).to_a

      `#{RuleFile.svn_cmd} up #{self.class.ruledocs_root}/snort-rules`
      rules.each do |rule|
        if commit_doc?(rule)
          rule.rule_doc.write_to_file if rule.rule_doc
          # set_rule_to_synched(rule)
        end
      end
      `#{RuleFile.svn_cmd} add --force #{self.class.ruledocs_root}/snort-rules`
      svn_result_output =
          `#{RuleFile.svn_cmd} ci #{self.class.ruledocs_root}/snort-rules -m "#{username} committed from Analyst Console"`
      Rails.logger.info svn_result_output.gsub("\n", "~\n   ")

      Rule.set_synched_state(Rule.where(id: rules))
    end
  end
end
