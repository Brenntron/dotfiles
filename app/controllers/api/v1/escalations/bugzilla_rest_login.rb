module API
  module V1
    module Escalations
      class BugzillaRestLogin < Grape::API
        include API::V1::Defaults

        resource "escalations/bugzilla_rest_login" do
          desc "log into bugzilla"
          params do
            optional :username, type: String, desc: "Bugzilla username."
            optional :password, type: String, desc: "Bugzilla password"
          end
          post "", root: :bugzilla_rest_login do
            byebug
          end
        end
      end
    end
  end
end

