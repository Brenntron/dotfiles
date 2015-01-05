module API
  module V1
    class Bugs < Grape::API
      include API::V1::Defaults

      resource :bugs do
        desc "Return all bugs"
        get "", root: :bugs do
          Bug.all
        end

        desc "Return a bug"
        params do
          requires :id, type: String, desc: "ID of the bug"
        end
        get ":id", root: "bug" do
          Bug.where(id: permitted_params[:id])
        end
      end
    end
  end
end