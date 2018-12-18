class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #protect_from_forgery with: :null_session, :if => Proc.new { |c| c.request.accept == 'application/json' }
  before_action :set_paper_trail_whodunnit
  before_action :require_login
  helper_method :current_user
  helper_method :xml_token

  private

  # TODO Unneeded?
  def require_login
    session[:previous_url] = request.url
  end

  def bugzilla_session()
    xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
    xmlrpc.token = request.headers['Xmlrpc-Token'] ? request.headers['Xmlrpc-Token'] : xml_token
    xmlrpc
  end

  def current_user
    user_from_request = User.from_request(params, request)
    if user_from_request && !session[:email]
      login_session = LoginSession.new(user_from_request)
      login_session.set_session(session)
    end

    if LoginSession.yet_active?(session, user_from_request&.email)
      @current_user ||= user_from_request
    else
      # force re-authentication
      nil
    end
  end

  def xml_token
    @xml_token ||= session[:token] if session[:token]
  end

  rescue_from ::CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json { head :forbidden, content_type: 'text/html' }
      format.html do
        if current_user
          redirect_to escalations_users_path
        else
          redirect_to new_escalations_session_path
        end
        flash[:alert] = exception.message
      end
      format.js   { head :forbidden, content_type: 'text/html' }
    end
  end
end
