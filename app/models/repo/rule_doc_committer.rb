module Repo
  # class RuleDocCommitter handles committing the rule docs.
  class RuleDocCommitter
    attr_reader :username

    def self.ruledocs_root
      @svn_pathname ||= Pathname.new('extras/ruledocs/snort-rules')
    end

    def ruledocs_root
      self.class.ruledocs_root
    end

    def initialize(rules, username: nil)
      @rules = rules
      @username = username
    end

    # method to get rules, refreshed from the database.
    def rules
      Rule.where(id: @rules).to_a
    end

    def commit_doc?(rule)
      case
        when Rule::PUBLISH_STATUS_PUBLISHING == rule.publish_status
          false #rule content failed to commit
        when rule.requires_doc? && !rule.has_doc?
          Rule.set_synched_state(rule)
          false
        when !(rule.rule_doc)
          false
        else
          true
      end
    end

    def call_svn(svn_args)
      Repo::RuleCommitter.call_svn(svn_args)
    end

    def commit_docs
      call_svn("up #{ruledocs_root}")

      rules.each do |rule|
        if commit_doc?(rule)
          rule.rule_doc.write_to_file
        end
      end

      call_svn("add --force #{ruledocs_root}")
      call_svn(%Q~ci #{ruledocs_root} -m "#{username} committed from Analyst Console"~)

      Rule.set_synched_state(Rule.where(id: rules))
    end
  end
end
