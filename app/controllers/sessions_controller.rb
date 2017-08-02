class SessionsController < ApplicationController

  def create
      respond_to do |format|
        format.html do
          begin
            login_session = User.login_user(params, request)
            login_session.set_session(session) if login_session
            login_session ? login_session.to_h : {}
          rescue StandardError => e
            return system_not_ready(e)
          rescue XMLRPC::FaultException => e
            return invalid_login_attempt(e)
          rescue Exception => e
            return invalid_login_attempt(e)
          end
          redirect_to '/bugs'
        end
        format.json do
          begin
            login_session = User.login_user(params, request)
            login_session.set_session(session) if login_session
            login_session ? login_session.to_h : {}
          rescue StandardError => e
            return system_not_ready(e)
          rescue XMLRPC::FaultException => e
            return invalid_login_attempt(e)
          rescue Exception => e
            return invalid_login_attempt(e)
          end
          render json: {  }
        end
      end
  end

  def logout
    #redirect_to login_url if reset_session.nil?
  end

  private

  def invalid_login_attempt(error_message)
    logger.error(error_message)
    logger.error(error_message.backtrace[0])
    logger.error(error_message.backtrace[1])
    logger.error(error_message.backtrace[2])
    warden.custom_failure!
    render :json => {:errors => ["#{error_message}"]}, :success => false, :status => :unauthorized
  end
  def system_not_ready(error_message)
    logger.error(error_message)
    logger.error(error_message.backtrace[0])
    logger.error(error_message.backtrace[1])
    logger.error(error_message.backtrace[2])
    render json:  {errors: ["#{error_message}"]}, success: false, status: 533
  end
end
