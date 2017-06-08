
# Simple exporter for the bugs view page.  If the user chooses no rules explicitly, export all rules associated with the bug
# otherwise, export only the rules checked
# 
module RuleSyntax
  class RuleExporter
    attr_reader :bug, :rules, :filename

    def initialize(args)
      if args[:bugzilla_id].present?
        @bug = Bug.find_by_id(args[:bugzilla_id])
      end

      if args[:rule_array].present?
        @rules = Rule.find(args[:rule_array])
      end 

      if @rules.blank? && @bug.blank?
        raise 'Rule Exporter needs either an array of rule ids or a bug id'
      end

      if @rules.blank?
        @rules = @bug.rules
      end
        
      @filename = "/tmp/exported_rules.rules" 
    end

    def export
      open(filename, 'w') { |f|
        rules.each do |rule|
          f.puts rule.rule_content 
        end 
      }  

      filename
    end

  end
end
