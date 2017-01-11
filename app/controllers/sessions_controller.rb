class SessionsController < ApplicationController

  def create
      respond_to do |format|
        format.json do
          begin
            resource = User.login_user(params, request)
            if resource[:user_id] && resource[:xmlrpc_token]
              session[:user] = resource[:user_id]
              session[:token] = resource[:xmlrpc_token]
            end
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
    render :json => {:errors => ["#{error_message}"]}, :success => false, :status => 500
  end
end
