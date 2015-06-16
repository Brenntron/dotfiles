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
            requires :rule_content, type: String, desc: "Compiled rule content"
            requires :documentation, type: String, desc: "A brief description to be used in the documentation."
          end
        end
        post "", root: "rule" do
          new_rule = Rule.parse_and_create_rule(permitted_params[:rule][:rule_content], permitted_params[:rule][:documentation])
          new_rule.associate_references(permitted_params[:rule][:rule_content])
          new_rule
        end

        desc "Edit a rule"
        params do
          requires :id, type: Integer, desc: "The database id of the rule you want to update."
          requires :rule, type: Hash do
            optional :rule_content, type: String, desc: "Compiled rule content"
            optional :connection, type: String, desc: "The connection string"
            optional :message, type: String, desc: "The message describing the rule"
            optional :detection, type: String, desc: "The detection for this rule"
            optional :flow, type: String, desc: "The flow"
            optional :metadata, type: String, desc: "Any meta data that goes with this"
            optional :classType, type: String, desc: "The type of rule"
            optional :references, type: String, desc: "any references this rule has"
            optional :sid, type: Integer, desc: "the sid number"
            optional :gid, type: Integer, desc: "the gid number"
            optional :rev, type: Integer, desc: "the version of the rule"
            optional :state, type: String, desc: "The state of the bug, Open, Closed, ReOpened,etc"
            optional :average_check, type: String, desc: "The person who created the bug"
            optional :average_match, type: String, desc: "The operating system that this bug affects"
            optional :average_nonmatch, type: String, desc: "What platform this bug runs on"
            optional :tested, type: String, desc: "How soon should this bug get fixed"
          end
        end
        put ":id", root: "rule" do
          if permitted_params[:rule][:rule_content]
            update_params = Rule.parse_and_create_rule(permitted_params[:rule][:rule_content])
          else
            update_params = permitted_params[:rule].reject { |k, v| v.nil? }
          end
          update_params[:state] = "UPDATED"
          update_params[:committed] = false
          Rule.update(permitted_params[:id], update_params)
        end


        #import multiple rules
        params do
          group :sids, :type => Array
          requires :id, desc: "IDs of the rules you wish to import"
        end
        post "import_multiple/:sids", root: "rule" do
          Rule.import_multiple(params[:sids])
        end


        #update a rule
        params do
          requires :id, type: Integer, desc: "the id for the rule to be updated"
        end
        post "update", root: "rule" do
          Rule.update(permitted_params[:id])
        end


        desc "remove a rule from the db only"
        params do
          requires :id, type: Integer, desc: "rule id"
        end
        delete ":id", root: "rule" do
          Rule.destroy(permitted_params[:id])
        end


        #delete a rule
        params do
          requires :id, type: Integer, desc: "the id for the rule to be deleted"
        end
        delete "delete", root: "rule" do
          Rule.remove_rule(permitted_params[:id])
        end

      end
    end
  end
end