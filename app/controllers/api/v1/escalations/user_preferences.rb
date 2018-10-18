module API
  module V1
    module Escalations
      class UserPreferences < Grape::API
        include API::V1::Defaults

        resource "escalations/user_preferences" do

          desc "Return all preferences of current user"
          get "", root: :user_preferences do
            user_preference = UserPreference.where(user_id: current_user.id).first

            if user_preference.present?
              user_preference.value
            end
          end

          desc "Update a preference (remove/add)"
          params do
            requires :data, type: Hash, desc: "Hash containing a preference key/value pair"
          end
          post "", root: "user_preferences" do
            columns = params.data

            user_preference = UserPreference.where(user_id: current_user.id).first

            name = 0
            state = 1

            if user_preference.present?
              json = JSON.parse(user_preference.value)

              columns.each do |column|
                json[column[name]] = column[state]
              end

              user_preference.value = json.to_json
              user_preference.save
            else
              UserPreference.create(user_id: current_user.id, value: {})

              user_preference = UserPreference.where(user_id: current_user.id).first

              json = JSON.parse(user_preference.value)

              columns.each do |column|
                json[column[name]] = column[state]
              end

              user_preference.value = json.to_json
              user_preference.save
            end



            user_preference.value
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