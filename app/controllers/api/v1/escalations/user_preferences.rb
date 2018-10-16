module API
  module V1
    module Escalations
      class UserPreferences < Grape::API
        include API::V1::Defaults


        resource :user_preferences do

          desc "Return all preferences of current user"
          get "", root: :user_preferences do
            current_user.user_preferences.to_json
          end

          desc "Create a preference"
          params do
            requires :name, type: String, desc: "The name of the preference."
            requires :value, type: String, desc: "Value to set in the preference."
          end
          post "", root: "user_preferences" do
            UserPreference.create(
                :name => permitted_params[:name],
                :value => permitted_params[:value],
                :user_id => current_user.id,
                )
          end

          desc "Return a specific preference"
          params do
            requires :name, type: String, desc: "Name of the preference"
          end
          get ":name", root: "user_preference" do
            UserPreference.where(name: permitted_params[:name]).first.to_json
          end

          desc "edit a preference" # Only supports changing values because I think the ability to change names would be too dangerous
          params do
            requires :id, type: Integer, desc: "The note's id in the database."
            optional :value, type: String, desc: "Preference value"
          end
          put ":id", root: "user_preference" do
            UserPreference.update(permitted_params[:id], value: permitted_params[:value])
          end


          desc "delete a preference"
          params do
            requires :id, type: Integer, desc: "Bugzilla id."
          end
          delete ":id", root: "user_preference" do
            UserPreference.destroy(permitted_params[:id])
          end

        end
      end
    end
  end
end