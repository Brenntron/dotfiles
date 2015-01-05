class SessionsController < ApplicationController
  def login
    begin
      raise Exception.new("You must specify a user parameter") if params[:user].nil?
      raise Exception.new("Do not specify a domain name in your user") if params[:user] =~ /@/

      xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
      xmlrpc.bugzilla_login(Bugzilla::User.new(xmlrpc), params[:user], params[:password])
      session[:bugzilla_cookie] = xmlrpc.token

      user = User.where(:username => "#{params[:user]}@#{Rails.configuration.bugzilla_domain}").first_or_create
      user.updated_at = Time.now
      user.save
      session[:user_id] = user.id

      # Everything is good
      redirect_to root_url

    rescue XMLRPC::FaultException => e
      redirect_to login_url, alert: e.to_s
    rescue Exception => e
      redirect_to login_url, alert: e.to_s
    end

  end

  def logout
    redirect_to login_url if reset_session.nil?
  end
end
