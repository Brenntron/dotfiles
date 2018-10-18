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

            case name
            when 'WebRepColumns'
              user_preference = UserPreference.where(user_id: current_user.id, name: 'WebRepColumns').first

              if user_preference.present?
                user_preference.value
              end
            end
          end

          desc "Update a preference for current user"
          params do
            requires :name, type: String, desc: "A string containing the type of preference to return"
            requires :data, type: Hash, desc: "Hash containing a preference key/value pair"
          end
          post "update", root: :user_preferences do
            name = params['name']

            case name
            when 'WebRepColumns'
              columns = params.data

              user_preference = UserPreference.where(user_id: current_user.id, name: 'WebRepColumns').first

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
                UserPreference.create(user_id: current_user.id, name: 'WebRepColumns', value: {})

                user_preference = UserPreference.where(user_id: current_user.id, name: 'WebRepColumns').first

                json = JSON.parse(user_preference.value)

                columns.each do |column|
                  json[column[name]] = column[state]
                end

                user_preference.value = json.to_json
                user_preference.save
              end

              user_preference.value
            end
          end
        end
      end
    end
  end
end