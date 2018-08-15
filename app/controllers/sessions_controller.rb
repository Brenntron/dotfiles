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
          if session[:previous_url].present?
            redirect_to session[:previous_url]
          else
            redirect_to(user_home)
          end
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
          render json: { }
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
    flash[:error] = error_message
    redirect_to root_url
  end
  def system_not_ready(error_message)
    logger.error(error_message)
    logger.error(error_message.backtrace[0])
    logger.error(error_message.backtrace[1])
    logger.error(error_message.backtrace[2])
    flash[:error] = error_message
    redirect_to root_url
  end

  def user_home
    case
      when can?(:manage, Admin)
        admin_root_path
      when can?(:read, Complaint)
        escalations_webcat_complaints_path
      when can?(:read, Dispute)
        escalations_webrep_disputes_path
      when can?(:read, EscalationBug)
        escalations_bugs_path
      when can?(:read, ResearchBug)
        bugs_path
      else
        escalations_users_path
    end
  end
end
