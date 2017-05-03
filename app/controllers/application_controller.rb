class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #protect_from_forgery with: :null_session, :if => Proc.new { |c| c.request.accept == 'application/json' }
  helper_method :current_user
  helper_method :xml_token

  private

  def require_login
    redirect_to root_url unless current_user
  end

  def bugzilla_session()
    xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
    xmlrpc.token = request.headers['Xmlrpc-Token'] ? request.headers['Xmlrpc-Token'] : xml_token
    return xmlrpc
  end

  def current_user
    user_from_reqeust = User.from_request(params, request)

    if LoginSession.yet_active?(session, user_from_reqeust.email)
      @current_user ||= user_from_reqeust
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
      format.html { redirect_to '/bugs'
                    flash[:alert] = exception.message }
      format.js   { head :forbidden, content_type: 'text/html' }
    end
  end
end
