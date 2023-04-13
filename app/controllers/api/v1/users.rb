module API
  module V1
    class Users < Grape::API
      include API::V1::Defaults

      resource :users do
        desc "Return all users"
        get "", root: :users do
          authorize!(:index, User)
          User.all
        end

        desc "Return all users as JSON"
        get "json", root: :users do
          authorize!(:index, User)

          users = User.all.where.not(display_name: [nil,""]).map{|customer| {name: customer.cvs_username, display_name: customer.display_name}}
          users.sort_by {|hash| hash[:name]}.to_json
        end

        desc "Return a user"
        params do
          requires :id, type: String, desc: "ID of the user"
        end
        get ":id", root: "user" do
          authorize!(:show, User)
          User.where(id: permitted_params[:id])
        end

        desc "Update a user"
        params do
          requires :id, type: String, desc: "ID of the user"
          optional :metrics_timeframe, type: Integer, desc: "the user's preferred time frame to view metrics'"
        end
        put ":id", root: "user" do
          authorize! :update_preferences, User
          current_user.update(metrics_timeframe: permitted_params[:metrics_timeframe])
        end
      end
    end
  end
end
