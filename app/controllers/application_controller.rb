class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session, :if => Proc.new { |c| c.request.accept == 'application/json' }
  before_filter :authenticate_from_token!

  private

  def authenticate_from_token!
    if !params[:api_key].blank? #this api key should be in the header not the params
      kerb_login = request.env['REMOTE_USER'] || Rails.configuration.ember_app[:remote_user]
      if params[:api_key] == Rails.configuration.ember_app[:api_key]
        user = User.where(kerberos_login: kerb_login).first_or_create do |new_record|
          new_record.kerberos_login = kerb_login
          new_record.email          = request.env['AUTHENTICATE_MAIL'] || Rails.configuration.backend_auth[:authenticate_email]
          new_record.cvs_username   = request.env['AUTHENTICATE_SAMACCOUNTNAME'] || Rails.configuration.backend_auth[:authenticate_cvs_username]
          new_record.cec_username   = request.env['AUTHENTICATE_CISCOCECUSERNAME'] || Rails.configuration.backend_auth[:authenticate_cec_username]
          new_record.display_name   = request.env['AUTHENTICATE_DISPLAYNAME'] || Rails.configuration.backend_auth[:authenticate_display_name]
          new_record.committer      = 'true'
          new_record.class_level    = 'unclassified'
          new_record.password       = 'password'
          new_record.password_confirmation= 'password'
        end
        if user
          sign_in user, store: false
        else
          raise("Could not create user")
        end
      end

    end
  end

  def bugzilla_session()
    xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
    xmlrpc.token = request.headers['Xmlrpc-Token']
    return xmlrpc
  end

end
