module API
  module V1
    class Rules < Grape::API
      include API::V1::Defaults

      resource :rules do
        before do
          PaperTrail.request.whodunnit = current_user.id if current_user.present?
        end
        desc "Checks rule to convert to SMTP"
        params do
          requires :rule_id, type: Integer, desc: "the id for the rule to be checked"
        end
        get ":rule_id/to_smtp", root: 'rule' do
          authorize!(:show, Rule)
          rule = Rule.find(permitted_params[:rule_id])
          rule.check_to_smtp
        end

        desc "Converts rule to SMTP"
        params do
          requires :rule_id, type: Integer, desc: "the id for the rule to be checked"
        end
        post ":rule_id/to_smtp", root: 'rule' do
          rule = Rule.find(permitted_params[:rule_id])
          authorize!(:show, rule) if rule
          if rule
            rule_smtp = rule.to_smtp
            references = rule_smtp.references.map do |ref|
              { reference_data: ref.reference_data, reference_type_name: ref.reference_type.name }
            end
            { rule: rule_smtp, references: references }
          else
            nil
          end
        end

        desc "Return a rule"
        params do
          requires :gid, type: Integer, desc: "gid of the rule"
          requires :sid, type: Integer, desc: "sid of the rule"
        end
        get "gids/:gid/sids/:sid", root: :rules do
          rule = Rule.find_or_load(permitted_params[:sid], permitted_params[:gid])
          authorize!(:show, rule) if rule
          rule ? {rule: rule} : nil
        end


        desc "Return a rule for duplications"
        params do
          requires :gid, type: Integer, desc: "gid of the rule"
          requires :sid, type: Integer, desc: "sid of the rule"
        end
        get "gids/:gid/sids/:sid/dup", root: :rules do
          rule = Rule.find_or_load(permitted_params[:sid], permitted_params[:gid])
          authorize!(:show, rule) if rule
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
          authorize!(:index, Rule)
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

          rule = Rule.by_sid(permitted_params[:sid], permitted_params[:gid]).first
          authorize!(:update, rule)
          Rule.update_action(rule, permitted_params[:rule][:rule_content])
        end


        desc "Revert rules by id"
        params do
          requires :rule_ids, type: Array[String]
        end
        put "revert", root: "rule" do
          std_api_v2 do
            authorize! :update, Rule
            rules = permitted_params[:rule_ids].map{|id| Rule.where(id: id).first}
            Rule.revert_rules_action(rules)
          end
        end

        desc "Revert a rule by sid"
        params do
          requires :gid, type: Integer, default: 1, desc: "gid of the rule"
          requires :sid, type: Integer, desc: "sid of the rule"
        end
        put "gids/:gid/sids/:sid/revert", root: "rule" do
          std_api_v2 do
            authorize! :update, Rule

            rule = Rule.by_sid(permitted_params[:sid], permitted_params[:gid]).first
            authorize!(:update, rule)
            Rule.revert_rules_action([rule])
          end
        end


        #commit rules
        desc "Commit rules by id"
        params do
          requires :rule_ids, type: Array[String]
          optional :username, type: String
          optional :bug_id,   type: Integer, desc: "Bugzilla id."
          optional :bugzilla_comment,   type: String
          optional :nodoc_override,     type: Boolean
        end
        put "commit", root: "rule" do
          std_api_v2 do
            # TODO authorization for committing rules to svn
            rules = Rule.where(id: permitted_params[:rule_ids]).where(state:['UPDATED','NEW']).all.to_a

            raise "There are no UPDATED or NEW rules in your selection!\nPlease select rules with a state of UPDATED or NEW." if rules.empty?
            raise "You are unauthorized to commit those rules!" unless rules.all? {|rule| can?(:publish, rule)}


            Repo::RuleCommitter.commit_rules_action(rules,
                                                    username: permitted_params[:username],
                                                    bugzilla_id: permitted_params[:bug_id],
                                                    new_bugzilla_comment: permitted_params[:bugzilla_comment],
                                                    xmlrpc: bugzilla_session,
                                                    nodoc_override: permitted_params[:nodoc_override])
          end
        end

        desc "Commit a rule by sid"
        params do
          requires :gid, type: Integer, default: 1, desc: "gid of the rule"
          requires :sid, type: Integer, desc: "sid of the rule"
          optional :username, type: String
          optional :bug_id,   type: Integer, desc: "Bugzilla id."
          optional :bugzilla_comment,   type: String
        end
        put "gids/:gid/sids/:sid/commit", root: "rule" do
          std_api_v2 do
            # TODO authorization for committing rules to svn
            rules = Rule.by_sid(permitted_params[:sid], permitted_params[:gid]).all.to_a

            raise "You must select a rule to commit!" if rules.empty?
            raise "You are unauthorized to commit those rules!" unless rules.all? {|rule| can?(:publish, rule)}


            Repo::RuleCommitter.commit_rules_action(rules,
                                                    username: permitted_params[:username],
                                                    bugzilla_id: permitted_params[:bug_id],
                                                    new_bugzilla_comment: permitted_params[:bugzilla_comment],
                                                    xmlrpc: bugzilla_session)

            if permitted_params[:bug_id].present?
              bug = Bug.find(permitted_params[:bug_id])
              xmlrpc = Bugzilla::Bug.new(bugzilla_session)
              if bug.committer_id != current_user.id || bug.committer_id.blank?
                bugzilla_options = {}
                bugzilla_options[:ids] = permitted_params[:bug_id]
                bugzilla_options[:qa_contact] = current_user.email
                xmlrpc.update(bugzilla_options.to_h)
                bug.committer_id = current_user.id
                bug.save
              end
            end

          end
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

          rule = Rule.where(id: permitted_params[:id]).first
          authorize!(:update, rule)
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
            Rule.find_or_load!(sid, 1)
          end
        end


        #update a rule
        params do
          requires :id, type: Integer, desc: "the id for the rule to be updated"
        end
        post "update", root: "rule" do
          authorize! :update, Rule

          Rule.update(permitted_params[:id])
        end

        params do
          optional :rule_id, type: Integer
          requires :rule_ids, type: Array[String]
        end
        patch ":rule_id/copy_doc", root: 'rule' do
          authorize!(:create, RuleDoc)
          RuleDoc.copy_doc_action(permitted_params[:rule_id],
                                  permitted_params[:rule_ids])
        end

        desc "Update the snort_doc_status on a given rules record."
        params do
          requires :rule_id, type: Integer
          requires :snort_doc_status, type: String
        end
        patch ":rule_id/snort_doc_status", root: 'rule' do
          authorize!(:update, Rule)
          rule = Rule.find(permitted_params[:rule_id])
          authorize!(:update, rule)
          rule.update!(snort_doc_status: permitted_params[:snort_doc_status])
        end
      end
    end
  end
end
