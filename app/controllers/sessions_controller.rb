class SessionsController < ApplicationController
  def create
    respond_to do |format|
      format.json do
        begin
          resource = User.login_user(params)
          if resource
            render :json => resource
          end
        rescue XMLRPC::FaultException => e
          return invalid_login_attempt(e)
        rescue Exception => e
          return invalid_login_attempt(e)
        end
      end
    end
  end

  def logout
    redirect_to login_url if reset_session.nil?
  end

  private

  def invalid_login_attempt(error_message)
    warden.custom_failure!
    render :json => {:errors => ["#{error_message}"]}, :success => false, :status => :unauthorized
  end
end
