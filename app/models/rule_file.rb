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

  # @return [Pathname] path (possibly relative) to the snort directory directory synchronized with svn
  def synch_pathname
    @synch_pathname ||= Rails.root.join(Repo::RuleContentCommitter.synch_root, relative_pathname)
  end

  # @return [Pathname] the path to the file in the working directory
  def working_pathname
    @working_pathname ||= Repo::RuleContentCommitter.working_pathname_of(relative_pathname)
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
        .map { |rule_group| new(Repo::RuleContentCommitter.relative_path_of(rule_group.nonnil_pathname)) }
  end

  def patch_file
    rules.each do |rule|
      rule.patch_file(Repo::RuleContentCommitter.working_pathname_of(rule.nonnil_pathname))
    end
  end

  # TODO move to RuleContentCommitter
  # read diffs from file to add new rules to bug
  def load_add_line(bugzilla_id)
    bug = Bug.where(bugzilla_id: bugzilla_id).first
    self.class.log("svn up #{synch_pathname}")
    `#{self.class.svn_cmd} up #{synch_pathname}`
    self.class.log("svn diff -r PREV:BASE #{synch_pathname}")
    `#{self.class.svn_cmd} diff -r PREV:BASE #{synch_pathname}`.each_line do |line|
      Rails.logger.info("*** diff line = '#{line}'")
      if (/^\+/ =~ line) && (/^\+\+\+/ !~ line) && (/sid:\s*\d+\s*;/ =~ line)
        Rails.logger.debug("*** diff line is an add")
        Repo::RuleContentCommitter.repo_add_line_new_rule_to_bug(line[1..-1], bug: bug)
      end
    end
  end

  # TODO move to RuleContentCommitter
  # read diffs from file to add to svn output
  def build_additional_output
    output = "\n"
    new_rules = ''
    `#{self.class.svn_cmd} up #{synch_pathname}`
    `#{self.class.svn_cmd} diff -r PREV:BASE #{synch_pathname}`.each_line do |line|
      if /^\+|^\-|^\@|^\=|^Index/ =~ line
        output += line
        if (/rev:\s*1\s*;/i =~ line) && (/^\+/ =~ line)
          new_rules += line[1..-1]
        end
      end
    end

    if !new_rules.empty?
      output += "\nNew Rules:\n"
      output += new_rules
    end
    output
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
end
