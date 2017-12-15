module API
  module WebAuthentication
    extend ActiveSupport::Concern

    included do
      before do
        error!("401 Unauthorized", 401) unless authenticated
      end

      helpers do
        def warden
          env['warden']
        end

        def authenticated
          return true if warden.authenticated?

          access_token = request.headers['Token'] #we just want to use headers and not url parameters
          @user = User.where("authentication_token = ?", access_token).first

          kerb_auth = request.env['REMOTE_USER'] ||  Rails.configuration.backend_auth[:default_remote_user]
          return access_token && !(@user.nil?) && kerb_auth
        end

        def current_user
          warden.user || @user
        end
      end
    end
  end
end
