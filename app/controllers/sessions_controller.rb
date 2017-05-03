class SessionsController < ApplicationController

  def create
      respond_to do |format|
        format.json do
          begin
            login_session = User.login_user(params, request)
            if login_session && login_session.success && login_session.user_id && login_session.xmlrpc_token
              session[:user] = login_session.user_id
              session[:email] = login_session.user_email
              session[:token] = login_session.xmlrpc_token
            end
            login_session.to_h
          rescue StandardError => e
            return system_not_ready(e)
          rescue XMLRPC::FaultException => e
            return invalid_login_attempt(e)
          rescue Exception => e
            return invalid_login_attempt(e)
          end
        end
      end
    render json: {  }
  end

  def logout
    #redirect_to login_url if reset_session.nil?
  end

  private

  def invalid_login_attempt(error_message)
    warden.custom_failure!
    render :json => {:errors => ["#{error_message}"]}, :success => false, :status => :unauthorized
  end
  def system_not_ready(error_message)
    render json:  {errors: ["#{error_message}"]}, success: false, status: 533
  end
end
