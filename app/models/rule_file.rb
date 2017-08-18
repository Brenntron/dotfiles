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
    self.class.log("svn up #{synch_pathname}")
    `#{self.class.svn_cmd} up #{synch_pathname}`
    self.class.log("svn diff -r PREV:BASE #{synch_pathname}")
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
end
