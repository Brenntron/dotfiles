class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session, :if => Proc.new { |c| c.request.accept == 'application/json' }
  before_filter :authenticate_from_token!

  private

  def authenticate_from_token!
    if !params[:api_key].blank?
      # user   = User.where(kerberos_login: request.env['REMOTE_USER']).first_or_create(kerberos_login: request.env['REMOTE_USER'])
      user   = User.where(kerberos_login: "nherbert@VRT.SOURCEFIRE.COM").first_or_create(kerberos_login: "nherbert@VRT.SOURCEFIRE.COM")
      if user &&  params[:api_key] == Rails.configuration.ember_app[:api_key]
        sign_in user, store: false
      end
    end
  end

  def bugzilla_session()
    xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
    xmlrpc.token = request.headers['Xmlrpc-Token']
    return xmlrpc
  end

end
