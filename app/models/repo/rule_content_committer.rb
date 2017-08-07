module Repo
  # class RuleContentCommitter handles committing the rule content.
  class RuleContentCommitter
    include Enumerable

    attr_reader :rule_files, :rules, :changed_rules, :unchanged_rules, :bug, :username

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

    def initialize(rules, bugzilla_id: nil, username: nil)
      @bug = bugzilla_id ? Bug.where(bugzilla_id: bugzilla_id).first : nil
      @username = username
      @rules = rules
      @changed_rules, @unchanged_rules = rules.partition { |rule| rule.content_changed? }

      @rule_files = self.class.collect_rule_files(@changed_rules)
    end

    def each(&block)
      rule_files.each(&block)
    end

    # Checks conditions which may prohibit a commit.
    # @param [Array[Rule]] rules collection of rules to check
    # @param [Boolean] nodoc_override true if should skip check for complete doc
    # @raise [RuntimeError] an exception if commit is prohibited.
    def self.prescreen!(rules, nodoc_override: false)

      raise 'Some of those rules are unchanged!' if rules.any? {|rule| rule.synched?}
      raise 'Some of those rules cannot be committed because they have changed!' if rules.any? {|rule| rule.stale_edit?}
      raise "Cannot commit with untested rules!" unless rules.all? {|rule| rule.tested?}
      raise "Cannot commit with incomplete rule docs!" unless nodoc_override || rules.all? { |rule| rule.doc_complete? }

    end

    def prescreen!(nodoc_override: false)
      self.class.prescreen!(rules, nodoc_override: nodoc_override)
    end

    # Commits the rule content of its collection of rule files and rules.
    def commit_rule_content
      rule_files.each {|rule_file| rule_file.checkout }
      rule_files.each {|rule_file| rule_file.patch_file}
    end
  end
end
