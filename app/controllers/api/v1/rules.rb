module API
  module V1
    class Rules < Grape::API
      include API::V1::Defaults

      resource :rules do
        desc "Return all rules"
        get "", root: :rules do
          Rule.all
        end

        desc "Return a rule"
        params do
          requires :id, type: String, desc: "ID of the rule"
        end
        get ":id", root: "rule" do
          Rule.where(id: permitted_params[:id])
        end
      end
    end
  end
end