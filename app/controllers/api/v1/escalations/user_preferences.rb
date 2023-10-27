module API
  module V1
    module Escalations
      class UserPreferences < Grape::API
        include API::V1::Defaults

        resource "escalations/user_preferences" do

          desc "Returns a preference for current user"
          params do
            requires :name, type: String
          end
          post "", root: :user_preferences do
            name = params['name']

            user_preference = UserPreference.where(user_id: current_user.id, name: name).first

            user_preference&.value

          end

          desc "Generates an API Key"
          params do
            requires :id, type: String
          end
          post "generateAPIkey", root: :user_preferences do
            @user = User.where(kerberos_login: params[:id]).first
            if @user.user_api_key
              @user.user_api_key.destroy
              @user.create_user_api_key
            else
              @user.create_user_api_key
            end
            {'key': @user.user_api_key.api_key}
          end

          desc "Update a preference for current user"
          params do
            requires :name, type: String, desc: "A string containing the type of preference to return"
            requires :data, type: Hash, desc: "Hash containing a preference key/value pair"
          end
          post "update", root: :user_preferences do
            name = params['name']
            columns = params['data']

            user_preference = UserPreference.create_with(value: {}).find_or_create_by(user_id: current_user.id, name: name)

            name = 0
            state = 1

            json = JSON.parse(user_preference.value)

            columns.each do |column|
              json[column[name]] = column[state]
            end

            user_preference.value = json.to_json
            user_preference.save

            end

            desc 'Remove a preference for current user'
            params do
              requires :name, type: String, desc: 'A string containing the type of preference to be destroyed'
            end

            delete 'destroy', root: :user_preferences do
              user_preference = UserPreference.find_by(user_id: current_user.id, name: params['name'])
              user_preference.destroy if user_preference.present?
            end
          end
        end
      end
  end
end