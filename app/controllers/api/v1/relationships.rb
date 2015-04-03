module API
  module V1
    class Relationships < Grape::API
      include API::V1::Defaults

      resource :relationships do
        desc "Return all user relationships"
        get "", root: :relationships do
          Relationship.all
        end



        desc "Create a relationship"
        # params do
        #   requires :relationship, type: Hash do
        #     requires :user_id, type: Integer, desc: 'The user id of the manager.',
        #     requires :team_member_id, type: Integer, desc: 'The user id of the team member under the manager.'
        #   end
        # end
        post "", root: "relationship" do
          Relationship.create(
            :user_id => params[:user_id],
            :team_member_id => params[:team_member_id]
          )
        end
        #
        #
        # desc "delete a relationship"
        # params do
        #   requires :id, type: Integer, desc: "relationship id"
        # end
        # delete ":id", root: "note" do
        #   Relationship.destroy(permitted_params[:id])
        # end

      end
    end
  end
end


