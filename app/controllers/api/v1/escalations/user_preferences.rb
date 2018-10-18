module API
  module V1
    module Escalations
      class UserPreferences < Grape::API
        include API::V1::Defaults

        resource "escalations/user_preferences" do

          desc "Return WebRep Dispute column preferences of current user"
          get "dispute_columns", root: :user_preferences do
            user_preference = UserPreference.where(user_id: current_user.id, name: 'WebRepColumns').first

            if user_preference.present?
              user_preference.value
            end
          end

          desc "Update a WebRep Dispute column preference for current user"
          params do
            requires :data, type: Hash, desc: "Hash containing a preference key/value pair"
          end
          post "dispute_columns", root: "user_preferences" do
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