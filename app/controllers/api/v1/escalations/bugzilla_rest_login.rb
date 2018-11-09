module API
  module V1
    module Escalations
      class BugzillaRestLogin < Grape::API
        include API::V1::Defaults
        include API::BugzillaRestSession

        resource "escalations/bugzilla_rest_login" do
          desc "log into bugzilla"
          params do
            optional :username, type: String, desc: "Bugzilla username"
            optional :password, type: String, desc: "Bugzilla password"
          end
          post "", root: :bugzilla_rest_login do
            std_api_v2 do
              token = bugzilla_rest_session.login(permitted_params[:username], permitted_params[:password])

              env['rack.session']['bugzilla_rest_api_token'] = token

              { status: 'success' }
            end
          end
        end
      end
    end
  end
end

