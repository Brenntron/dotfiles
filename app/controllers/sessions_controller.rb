class SessionsController < ApplicationController
  def create
    respond_to do |format|
      format.json do
        resource = User.where("email=?", params[:user][:email]).first
        return invalid_login_attempt unless resource

        if resource.valid_password?(params[:user][:password]) #devise takes care of password checking
          resource.ensure_authentication_token                #make sure the user has a token generated
          render :json=> {
              :success=>true,
              :user_token=>resource.authentication_token,     #this must be called user_token for the ember app session to persist
              :user_email=>resource.email                     #this also ust be called user_email for the ember app session to persist
          }
          return
        end
        invalid_login_attempt
      end
    end
  end

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
  private

  def invalid_login_attempt
    warden.custom_failure!
    render :json => { :errors => ["Invalid email or password."] },  :success => false, :status => :unauthorized
  end
end
