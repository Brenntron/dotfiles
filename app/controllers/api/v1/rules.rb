module API
  module V1
    class Rules < Grape::API
      include API::V1::Defaults

      resource :rules do

        desc "import all existing rules"
        get 'import_all' do
          true
        end


        desc "import existing rule"
        params do
          requires :id, type: Integer, desc: "rule sid."
        end
        route_param "import/:id" do
          get do
            Rule.import_rule(permitted_params[:id])
          end
        end


        desc "Return a rule"
        params do
          requires :id, type: String, desc: "ID of the rule"
        end
        get ":id", root: "rule" do
          Rule.where(id: permitted_params[:id]).first
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


        desc "create a rule"
        params do
          requires :rule, type: Hash do
            requires :rule_content,     type: String,  desc: "Compiled rule content"
            optional :bug_id,           type: Integer, desc: "Id of the bug associated with this rule"
            optional :detection,        type: String,  desc: "Detection for the new rule"
            optional :class_type,       type: String,  desc: "Classification of the new rule"
            optional :rule_category_id, type: Integer, desc: "Rule Category"

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
          new_rule = Rule.create(Rule.parse_and_create_rule(permitted_params[:rule][:rule_content]))
          new_rule.bugs << Bug.where(id:permitted_params[:rule][:bug_id]).first if permitted_params[:rule][:bug_id]
          new_rule.associate_references(permitted_params[:rule][:rule_content])
          new_rule.update(detection:permitted_params[:rule][:detection].strip!, class_type:permitted_params[:rule][:class_type]) if new_rule.state == 'FAILED'
          new_rule.update(rule_category_id: permitted_params[:rule][:rule_category_id], publish_status: Rule::PUBLISH_STATUS_NEW)
          new_rule.create_rule_doc(permitted_params[:rule][:rule_doc])
          new_rule
        end


        #revert a rule
        params do
          requires :ids, type: Array[String]
        end
        put "revert", root: "rule" do
          authorize! :update, Rule
          permitted_params[:ids].each do |id|
            rule = Rule.where(id: id).first
            rule.import
          end
          true
        end


        desc "Edit a rule"
        params do
          requires :id, type: Integer, desc: "The database id of the rule you want to update."
          requires :rule, type: Hash do
            optional :rule_content, type: String, desc: "Compiled rule content"
            optional :revert, type: Boolean, desc: "Revert rule to CVS copy?"

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
          update_params = Rule.parse_and_create_rule(permitted_params[:rule][:rule_content])
          rule = Rule.where(id:permitted_params[:id]).first
          if permitted_params[:rule][:revert]
            update_params[:cvs_rule_parsed] = update_params[:rule_parsed]
          else
            unless rule.sid.nil? || (update_params[:state] == 'FAILED')
              update_params[:state] = "UPDATED"
              update_params[:publish_status] = Rule::PUBLISH_STATUS_CURRENT_EDIT unless rule.stale_edit?
              update_params[:committed] = false
            end
          end
          rule.update_references(permitted_params[:rule][:rule_content])
          rule.rule_doc.present? ? rule.rule_doc.update(permitted_params[:rule][:rule_doc]) : rule.create_rule_doc(permitted_params[:rule][:rule_doc])
          rule.update(update_params)
          rule
        end

        #import multiple rules
        params do
          group :sids, :type => Array
          requires :id, desc: "IDs of the rules you wish to import"
        end
        post "import_multiple/:sids", root: "rule" do
          authorize! :create, Rule
          Rule.import_multiple(params[:sids])
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


        desc "remove a rule from the db only"
        params do
          requires :id, type: Integer, desc: "rule id"
        end
        delete ":id", root: "rule" do
          authorize! :destroy, Rule
          Rule.destroy(permitted_params[:id])
        end


        #delete a rule
        params do
          requires :id, type: Integer, desc: "the id for the rule to be deleted"
        end
        delete "delete", root: "rule" do
          authorize! :destroy, Rule
          Rule.remove_rule(permitted_params[:id])
        end
      end
    end
  end
end