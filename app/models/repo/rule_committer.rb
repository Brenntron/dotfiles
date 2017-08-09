module Repo
  # class RuleCommitter handles committing rule content and rule docs.
  # Calls RuleContentCommitter class to commit the rule content.
  class RuleCommitter
    include Enumerable

    attr_reader :content_committer, :rule_files, :rules, :changed_rules, :unchanged_rules, :bug, :user, :username

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

      @content_committer =
          Repo::RuleContentCommitter.new(rules, bugzilla_id: bugzilla_id, user: user, username: username)
    end #initialize

    def event_start
      @rule_commit_event = RuleEvent::RuleCommitEvent.start(bug.bugzilla_id, rules, user.id)
    end #event_start

    def event_success
      @rule_commit_event&.update(failed: false)
    end

    def event_complete
      @rule_commit_event&.update(completed: true)
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
