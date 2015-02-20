module API
  module V1
    class Rules < Grape::API
      include API::V1::Defaults

      resource :rules do

        #get all the rules OR get a rule by sid parameter
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

        # get a single rule
        desc "Return a rule"
        params do
          requires :id, type: String, desc: "ID of the rule"
        end
        get ":id", root: "rule" do
          Rule.where(id: permitted_params[:id]).first
        end

        #create rule using rule text
        params do
          requires :content, type: String, desc: "The text content of the rule to be created"
        end
        post do
          Rule.create_a_rule(permitted_params[:content])
        end

        #import rule via sid
        params do
          requires :sid, type: String, desc: "ID of the rule"
        end
        post "import/:sid", root: "rule" do
          Rule.import(permitted_params[:sid])
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