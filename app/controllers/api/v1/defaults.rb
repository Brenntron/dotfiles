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
            kerb_auth = request.env['REMOTE_USER'] ||  Rails.configuration.backend_auth[:default_remote_user]
            access_token = request.headers['Token'] #we just want to use headers and not url parameters
            return true if warden.authenticated?
            @user = User.where("authentication_token = ?", access_token).first
            return access_token && !(@user.nil?) && kerb_auth
          end

          def current_user
            return nil if /_#{Rails.configuration.app_name}_session/ !~ @request.headers['Cookie']
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
              xmlrpc.token = request.headers['Xmlrpc-Token']
            end
            xmlrpc
          end

          def bugzilla_rest_session
            token = headers['X-Bugzilla-Restapi-Token']
            token = env['rack.session']['bugzilla_rest_api_token'] unless token.present?
            BugzillaRest::Session.new(api_key: current_user.bugzilla_api_key, token: token)
          end

          # Standard (our standard) handling of an exception
          # @param [Exception, #read] exception is the exception to report
          # @param [Fixnum] status is the HTTP status code
          def std_exception(exception, status: 500)
            Rails.logger.error("exception: #{exception.message}")
            exception.backtrace[0..4].each_with_index do |traceline, index|
              Rails.logger.error("backtrace[#{index}] #{traceline}")
            end
            error!(message: exception.message, status: status, success: false)
          end

          # Transition to implement V2 API handling from the V1 API
          #
          # This method was implemented to prototype a new error handling for V2.
          # In a V1 API method, put the code in a block for this method,
          # and the response will be handled in the V2 API standard.
          def std_api_v2
            yield
          rescue CanCan::AccessDenied => exception
            std_exception(exception, status: 403)
          rescue ActiveRecord::RecordNotFound => exception
            std_exception(exception, status: 404)
          rescue Grape::Exceptions::ValidationErrors => exception
            std_exception(exception, status: 406)
          rescue => exception
            std_exception(exception)
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
            error_response(message: "Internal server error: #{e}", status: 500)
          end
        end

        rescue_from CanCan::AccessDenied do |e|
          error_response(message: e.message, status: 403)
        end

        rescue_from XMLRPC::FaultException do |e|
          error_response(message: e.message, status: 500)
        end

        rescue_from Grape::Exceptions::ValidationErrors do |e|
          error_response(message: e.message, status: 406)
        end

      end
    end
  end
end
