class SessionsController < ApplicationController

  def create
    if !params[:api_key].blank?
      respond_to do |format|
        format.json do
          begin
            raise Exception.new("Unauthorized Access.") if params[:api_key].blank? || params[:api_key] != Rails.configuration.ember_app[:api_key]
            resource = User.login_user(params, request)
            if resource[:user_id] && resource[:xmlrpc_token]
              session[:user] = resource[:user_id]
              session[:token] = resource[:xmlrpc_token]
            end
          rescue XMLRPC::FaultException => e
            return invalid_login_attempt(e)
          rescue Exception => e
            return invalid_login_attempt(e)
          end
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
end
