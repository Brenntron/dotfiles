module API
  module V1
    module Defaults
      # if you're using Grape outside of Rails, you'll have to use Module#included hook
      extend ActiveSupport::Concern

      included do
        # common Grape settings
        version 'v1' # path-based versioning by default
        default_format :json
        format :json
        formatter :json, Grape::Formatter::ActiveModelSerializers


        before do
          error!("401 Unauthorized", 401) unless authenticated
        end

        helpers do
          def warden
            env['warden']
          end

          def authenticated
            access_token = request.headers['Token'] #we just want to use headers and not url parameters
            return true if warden.authenticated?
            access_token && @user = User.where("authentication_token = ?", access_token)
          end

          def current_user
            warden.user || @user
          end

          def permitted_params
            @permitted_params ||= declared(params, include_missing: false)
          end

          params :pagination do
            optional :page, type: Integer
            optional :per_page, type: Integer
          end

          def logger
            Rails.logger
          end

          def bugzilla_session
            xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
            if current_user
              xmlrpc.token = current_user.first.bugzilla_token
            end
            xmlrpc
          end
        end

        # global handler for simple not found case
        rescue_from ActiveRecord::RecordNotFound do |e|
          error_response(message: e.message, status: 404)
        end

        # global exception handler, used for error notifications
        rescue_from :all do |e|
          if Rails.env.development?
            raise e
          else
            Raven.capture_exception(e)
            error_response(message: "Internal server error", status: 500)
          end
        end

        # # HTTP header based authentication
        # before do
        #   error!('Unauthorized', 401) unless headers['Authorization'] == "some token"
        # end
      end
    end
  end
end
