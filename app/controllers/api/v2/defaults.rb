module API::V2::Defaults
  # if you're using Grape outside of Rails, you'll have to use Module#included hook
  extend ActiveSupport::Concern

  included do
    # common Grape settings
    version 'v2' # path-based versioning by default

    before do
      error!("401 Unauthorized", 401) unless current_user
    end


    helpers do
      def current_user
        unless @current_user
          api_key_str =
              case
                when request.headers['Api-Key'] #Preferred by RFC 6648
                  request.headers['Api-Key']
                when request.headers['X-Api-Key'] #Encouraged to not prohibit by RFC 6648
                  request.headers['X-Api-Key']
                when params['Api-Key']
                  params['Api-Key']
              end
          @current_user =
              case
                when api_key_str
                  user_api_key = UserApiKey.where(api_key: request.headers['Api-Key']).first
                  user_api_key.user if user_api_key
                when request.headers['Token'] && request.env['REMOTE_USER']
                  kerb_auth = request.env['REMOTE_USER']
                  access_token = request.headers['Token'] #we just want to use headers and not url parameters
                  kerb_auth && User.where("authentication_token = ?", access_token).first
                # when Rails.configuration.backend_auth[:default_remote_user] && !(Rails.env.production? || Rails.env.staging?)
                #   User.where(cvs_username: Rails.configuration.backend_auth[:default_remote_user]).first
                else
                  nil
              end
        end
        @current_user
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

      # Standard (our standard) handling of an exception
      # @param [Exception, #read] exception is the exception to report
      # @param [Fixnum] status is the HTTP status code
      def std_exception(exception, status: 500)
        Rails.logger.error("exception: #{exception.message}")
        exception.backtrace[0..4].each_with_index do |traceline, index|
          Rails.logger.error("backtrace[#{index}] #{traceline}")
        end
        error!(message: "Internal server error: '#{exception.message}'", status: status, success: false)
      end

      # Transition to implement V2 API handling from the V1 API
      #
      # This method was implemented to prototype a new error handling for V2.
      # In a V1 API method, put the code in a block for this method,
      # and the response will be handled in the V2 API standard.
      def std_api_v2
        logger.debug "std_api_v2 is deprecated in V2.  This had been provided for transition from V1."
        yield
      end
    end

    # global exception handler, used for error notifications
    rescue_from :all do |exception|
      if Rails.env.development? && false
        raise exception
      else
        std_exception(exception, status: 500)
      end
    end

    rescue_from CanCan::AccessDenied do |exception|
      std_exception(exception, status: 403)
    end

    rescue_from ActiveRecord::RecordNotFound do |exception|
      std_exception(exception, status: 404)
    end

    rescue_from XMLRPC::FaultException do |exception|
      std_exception(exception, status: 500)
    end

    rescue_from Grape::Exceptions::ValidationErrors do |exception|
      std_exception(exception, status: 406)
    end

  end
end
