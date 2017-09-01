module API
  module V1
    class Rules < Grape::API
      include API::V1::Defaults

      resource :rules do

        desc "Return a rule"
        params do
          requires :gid, type: Integer, desc: "gid of the rule"
          requires :sid, type: Integer, desc: "sid of the rule"
        end
        get "gids/:gid/sids/:sid", root: :rules do
          rule = Rule.find_or_load(permitted_params[:sid], permitted_params[:gid])
          rule ? {rule: rule} : nil
        end


        desc "Return a rule for duplications"
        params do
          requires :gid, type: Integer, desc: "gid of the rule"
          requires :sid, type: Integer, desc: "sid of the rule"
        end
        get "gids/:gid/sids/:sid/dup", root: :rules do
          rule = Rule.find_or_load(permitted_params[:sid], permitted_params[:gid])
          if rule
            {rule: rule.dup}
          else
            nil
          end
        end


        desc "Return all rules"
        params do
          optional :sid, type: String, desc: "SID of the rule"
        end
        get "", root: :rules do
          if permitted_params[:sid]
            Rule.where(sid: permitted_params[:sid]).first
          else
            Rule.all
          end
        end


        # Creates a rule and its associations
        # @return [Rule]
        desc "create a rule from rule content"
        params do
          requires :rule, type: Hash do
            requires :rule_content,     type: String,  desc: "Compiled rule content"
            optional :bug_id,           type: Integer, desc: "Id of the bug associated with this rule"
            requires :rule_doc, type: Hash do
              requires :summary,           type: String, desc: "Rule Doc Summary"
              optional :impact,            type: String, desc: "Rule Doc Impact"
              optional :details,           type: String, desc: "Rule Doc Detailed Information"
              optional :affected_sys,      type: String, desc: "Rule Doc Affected Systems"
              optional :attack_scenarios,  type: String, desc: "Rule Doc Attack Scenarios"
              optional :ease_of_attack,    type: String, desc: "Rule Doc Ease of Attack"
              optional :false_positives,   type: String, desc: "Rule Doc False Positives"
              optional :false_negatives,   type: String, desc: "Rule Doc False Negatives"
              optional :corrective_action, type: String, desc: "Rule Doc Corrective Action"
              optional :contributors,      type: String, desc: "Rule Doc Contributors"
            end
          end
        end
        post "", root: "rule" do
          authorize! :create, Rule
          ::PaperTrail.whodunnit = current_user.display_name ? current_user.display_name : current_user.cvs_username
          Rule.create_action(permitted_params[:rule][:rule_content],
                             permitted_params[:rule][:rule_doc],
                             permitted_params[:rule][:bug_id])
        end

        # Creates a rule and its associations
        # @return [Rule]
        desc "create a rule from fields given in parts"
        params do
          requires :rule, type: Hash do
            requires :connection, type: Hash do
              requires :action,         type: String,  desc: "Action ex: 'alert'"
              requires :protocol,       type: String,  desc: "Protocol ex: 'tcp'"
              requires :src,            type: String,  desc: "Source addresses ex: '$SSH_SERVERS'"
              requires :srcport,        type: String,  desc: "Source ports ex: '$SSH_PORTS'"
              requires :direction,      type: String,  desc: "Direction ex: '->'"
              requires :dst,            type: String,  desc: "Dst addresses ex: '$SSH_SERVERS'"
              requires :dstport,        type: String,  desc: "Dst ports ex: '$SSH_PORTS'"
            end
            optional :rule_category_id, type: Integer, desc: "Rule Category pkey if known"
            optional :rule_category,    type: String,  desc: "Rule Category name ex: 'BLACKLIST'"
            requires :message,          type: String,  desc: "Message part no category ex: 'possible sql injection attempt'"
            requires :flow,             type: String,  desc: "Flow ex: 'to_client,established'"
            requires :detection,        type: String,  desc: "Detection ex: 'content:\"200\"; flowbits:isset,http.mokes;'"
            requires :metadata,         type: String,  desc: "Metadata ex: 'impact_flag red, service dns'"
            requires :class_type,       type: String,  desc: "Classtype ex: 'attempted-user'"
            requires :references,       type: String,  desc: "References ex: 'reference:bugtraq,18358; reference:cve,2006-2371;'"
            optional :bug_id,           type: Integer, desc: "Id of the bug associated with this rule"

            requires :rule_doc, type: Hash do
              requires :summary,           type: String, desc: "Rule Doc Summary"
              optional :impact,            type: String, desc: "Rule Doc Impact"
              optional :details,           type: String, desc: "Rule Doc Detailed Information"
              optional :affected_sys,      type: String, desc: "Rule Doc Affected Systems"
              optional :attack_scenarios,  type: String, desc: "Rule Doc Attack Scenarios"
              optional :ease_of_attack,    type: String, desc: "Rule Doc Ease of Attack"
              optional :false_positives,   type: String, desc: "Rule Doc False Positives"
              optional :false_negatives,   type: String, desc: "Rule Doc False Negatives"
              optional :corrective_action, type: String, desc: "Rule Doc Corrective Action"
              optional :contributors,      type: String, desc: "Rule Doc Contributors"
            end
          end
        end
        post "parts", root: "rule" do
          authorize! :create, Rule
          ::PaperTrail.whodunnit = current_user.display_name ? current_user.display_name : current_user.cvs_username
          Rule.create_parts_action(permitted_params[:rule],
                                   permitted_params[:rule][:rule_doc],
                                   permitted_params[:rule][:bug_id])
        end


        desc "Edit a rule"
        params do
          requires :gid, type: Integer, default: 1, desc: "gid of the rule"
          requires :sid, type: Integer, desc: "sid of the rule"
          requires :rule, type: Hash do
            requires :rule_content, type: String, desc: "Compiled rule content"
          end
        end
        put "gids/:gid/sids/:sid", root: "rule" do
          authorize! :update, Rule
          ::PaperTrail.whodunnit = current_user.display_name ? current_user.display_name : current_user.cvs_username
          rule = Rule.by_sid(permitted_params[:sid], permitted_params[:gid]).first
          Rule.update_action(rule, permitted_params[:rule][:rule_content])
        end


        #revert rules
        params do
          requires :rule_ids, type: Array[String]
        end
        put "revert", root: "rule" do
          authorize! :update, Rule
          rules = permitted_params[:rule_ids].map{|id| Rule.where(id: id).first}
          Rule.revert_rules_action(rules)
        end

        desc "Revert a rule"
        params do
          requires :gid, type: Integer, default: 1, desc: "gid of the rule"
          requires :sid, type: Integer, desc: "sid of the rule"
        end
        put "gids/:gid/sids/:sid/revert", root: "rule" do
          authorize! :update, Rule
          ::PaperTrail.whodunnit = current_user.display_name ? current_user.display_name : current_user.cvs_username
          rule = Rule.by_sid(permitted_params[:sid], permitted_params[:gid]).first
          Rule.revert_rules_action([rule])
        end


        #commit rules
        params do
          requires :rule_ids, type: Array[String]
          optional :username, type: String
          optional :bug_id,   type: Integer, desc: "Bugzilla id."
          optional :nodoc_override, type: Boolean
        end
        put "commit", root: "rule" do
          rules = Rule.where(id: permitted_params[:rule_ids]).all.to_a

          raise "You must select a rule to commit!" if rules.empty?
          raise "You are unauthorized to commit those rules!" unless rules.all? {|rule| can?(:publish, rule)}

          Repo::RuleCommitter.commit_rules_action(rules,
                                                  username: permitted_params[:username],
                                                  bugzilla_id: permitted_params[:bug_id],
                                                  xmlrpc: bugzilla_session,
                                                  nodoc_override: permitted_params[:nodoc_override])
        end

        desc "Commit a rule"
        params do
          requires :gid, type: Integer, default: 1, desc: "gid of the rule"
          requires :sid, type: Integer, desc: "sid of the rule"
          optional :username, type: String
          optional :bug_id,   type: Integer, desc: "Bugzilla id."
        end
        put "gids/:gid/sids/:sid/commit", root: "rule" do
          rules = Rule.by_sid(permitted_params[:sid], permitted_params[:gid]).all.to_a

          raise "You must select a rule to commit!" if rules.empty?
          raise "You are unauthorized to commit those rules!" unless rules.all? {|rule| can?(:publish, rule)}

          Repo::RuleCommitter.commit_rules_action(rules,
                                                  username: permitted_params[:username],
                                                  bugzilla_id: permitted_params[:bug_id])
        end


        # Updates a rule and its associations
        # @return [Rule]
        desc "Edit a rule from the id primary key"
        params do
          requires :id, type: Integer, desc: "The database id of the rule you want to update."
          requires :rule, type: Hash do
            optional :rule_content, type: String, desc: "Compiled rule content"

            requires :rule_doc, type: Hash do
              requires :summary,           type: String, desc: "Rule Doc Summary"
              optional :impact,            type: String, desc: "Rule Doc Impact"
              optional :details,           type: String, desc: "Rule Doc Detailed Information"
              optional :affected_sys,      type: String, desc: "Rule Doc Affected Systems"
              optional :attack_scenarios,  type: String, desc: "Rule Doc Attack Scenarios"
              optional :ease_of_attack,    type: String, desc: "Rule Doc Ease of Attack"
              optional :false_positives,   type: String, desc: "Rule Doc False Positives"
              optional :false_negatives,   type: String, desc: "Rule Doc False Negatives"
              optional :corrective_action, type: String, desc: "Rule Doc Corrective Action"
              optional :contributors,      type: String, desc: "Rule Doc Contributors"
            end
          end
        end
        put ":id", root: "rule" do
          authorize! :update, Rule
          ::PaperTrail.whodunnit = current_user.display_name ? current_user.display_name : current_user.cvs_username
          rule = Rule.where(id: permitted_params[:id]).first
          Rule.update_action(rule,
                             permitted_params[:rule][:rule_content],
                             permitted_params[:rule][:rule_doc])
        end

        params do
          optional :sid, type: Integer
          optional :gid, type: Integer, default: 1
          optional :rule, type: JSON
        end
        put ":gid/:sid/rule-parts", root: "rule" do
          Rule.update_parts_action(permitted_params[:sid], permitted_params[:gid], permitted_params[:rule])
          true
        end

        #load multiple rules
        params do
          requires :sids, type: Array[Integer]
        end
        get "bulk_fetch/:sids", root: "rule" do
          authorize! :create, Rule
          permitted_params[:sids].map do |sid|
            Rule.find_or_load(sid, 1)
          end
        end


        #update a rule
        params do
          requires :id, type: Integer, desc: "the id for the rule to be updated"
        end
        post "update", root: "rule" do
          authorize! :update, Rule
          ::PaperTrail.whodunnit = current_user.cvs_username
          Rule.update(permitted_params[:id])
        end
      end
    end
  end
end