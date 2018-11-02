module API
  module V1
    module Escalations
      class BugzillaRestLogin < Grape::API
        include API::V1::Defaults

        resource "escalations/bugzilla_rest_login" do
          desc "log into bugzilla"
          params do
            optional :username, type: String, desc: "Bugzilla username"
            optional :password, type: String, desc: "Bugzilla password"
          end
          post "", root: :bugzilla_rest_login do
            std_api_v2 do

              # session_id = cookies['_analyst_console_escalations_session']
              # session = Session.where(session_id: session_id).first
              # session_data = JSON.parse(session.data)

              token = bugzilla_rest_session.login(permitted_params[:username], permitted_params[:password])

              env['rack.session']['bugzilla_rest_api_token'] = token

              # session_data['value']['bugzilla_rest_token'] = token
              # session.update!(data: session_data.to_json)

              { status: 'success' }
            end
          end
        end
      end
    end
  end
end

