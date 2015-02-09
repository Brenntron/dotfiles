module API
  module V1
    class Rules < Grape::API
      include API::V1::Defaults

      resource :rules do
        desc "Return all rules"
        get "", root: :rules do
          Rule.all
        end

        desc "Return a rule by sid"
        params do
          requires :sid, type: String, desc: "SID of the rule"
        end
        get ":sid", root: "rule" do
          Rule.where(sid: permitted_params[:sid])
        end
      end
    end
  end
end