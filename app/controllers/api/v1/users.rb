module API
  module V1
    class Users < Grape::API
      include API::V1::Defaults

      resource :users do
        desc "Return all users"
        get "", root: :users do
          User.all
        end

        desc "Return a user"
        params do
          requires :id, type: String, desc: "ID of the user"
        end
        get ":id", root: "user" do
          User.where(id: permitted_params[:id])
        end

        desc "Update a user"
        params do
          requires :id, type: String, desc: "ID of the user"
          optional :metrics_timeframe, type: Integer, desc: "the user's preferred time frame to view metrics'"
        end
        put ":id", root: "user" do
          current_user.update_attributes(metrics_timeframe: permitted_params[:metrics_timeframe])
        end

        desc "Add a new team member"
        params do
          requires :id, type: String, desc: "ID of the user"
        end
        put "team/add/:id", root: "user" do
          team_member_id = permitted_params[:id].to_i
          unless current_user.team_member_ids.include?(team_member_id)
            current_user.team_members << User.find(team_member_id)
          end
        end

        desc "Remove a team member"
        params do
          requires :id, type: String, desc: "ID of the user"
        end
        put "team/remove/:id", root: "user" do
          team_member_id = permitted_params[:id].to_i
          if current_user.team_member_ids.include?(team_member_id)
            current_user.team_members.delete(User.find(team_member_id))
          end
        end

      end
    end
  end
end