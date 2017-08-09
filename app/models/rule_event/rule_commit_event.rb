module RuleEvent
  # Object to record event of committing a rule, both rule content and rule docs.
  class RuleCommitEvent < Task
    def self.start(bug_id, rules, user_id)
      create(task_type: 'rule commit', bug_id: bug_id, user_id: user_id, completed: false, failed: true).tap do |event|
        event.rules = rules
      end
    end
  end
end
