class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #protect_from_forgery with: :null_session, :if => Proc.new { |c| c.request.accept == 'application/json' }
  helper_method :current_user
  helper_method :xml_token

  private

  def bugzilla_session()
    xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
    xmlrpc.token = request.headers['Xmlrpc-Token'] ? request.headers['Xmlrpc-Token'] : xml_token
    return xmlrpc
  end


  def current_user
    @current_user ||= User.find(session[:user]) if session[:user]
  end

  def xml_token
    @xml_token ||= session[:token] if session[:token]
  end


end
