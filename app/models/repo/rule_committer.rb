module Repo
  class RuleCommitter
    attr_reader :rule_files, :rules, :changed_rules, :unchanged_rules, :username

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

    def initialize(rules, username: nil)
      @username = username
      @rules = rules
      @changed_rules, @unchanged_rules = rules.partition { |rule| rule.content_changed? }

      @rule_files = self.class.collect_rule_files(@changed_rules)
    end

    def each(&block)
      rule_files.each(&block)
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

    def commit_docs
      log("publishing rule docn #{rules.count} rules")
      Rule.set_pubdoc_state(Rule.where(id: unchanged_rules))

      #refresh rule objects from database
      @rules = Rule.where(id: @rules)

      `#{RuleFile.svn_cmd} up extras/rulesdocs/snort-rules`
      rules.each do |rule|
        if commit_doc?(rule)
          rule.rule_doc.write_to_file if rule.rule_doc
          # set_rule_to_synched(rule)
        end
      end
      `#{RuleFile.svn_cmd} add --force extras/rulesdocs/snort-rules`
      `#{RuleFile.svn_cmd} ci extras/rulesdocs/snort-rules -m "#{username} committed from Analyst Console"`

      Rule.set_synched_state(Rule.where(id: rules))
    end
  end
end
