class User < ActiveRecord::Base
  has_many :bugs
  before_save :ensure_authentication_token
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable


  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
  end

  private

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end

  def self.login_user(params)
    begin
      xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
      xmlrpc.bugzilla_login(Bugzilla::User.new(xmlrpc), params[:user][:email].gsub("@#{Rails.configuration.bugzilla_domain}",""), params[:user][:password])

      user = User.where("email=?", params[:user][:email]).first_or_create do |new_record|
        new_record.email          = params[:user][:email]
        new_record.cvs_username   = params[:user][:email].gsub("@#{Rails.configuration.bugzilla_domain}","")
        new_record.password       = params[:user][:password]
        new_record.committer      = 'true'
      end
      user.updated_at = Time.now
      user.bugzilla_token = xmlrpc.token
      raise Exception.new("Error signing in. Please use full email as your login.") unless user.save

      if user.valid_password?(params[:user][:password]) #devise takes care of password checking
        user.ensure_authentication_token #make sure the user has a token generated
        resource = {
            :success => true,
            :xmlrpc_token => xmlrpc.token,
            :user_token => user.authentication_token, #this must be called user_token for the ember app session to persist
            :user_email => user.email #this also ust be called user_email for the ember app session to persist
        }
        return resource
      else
        raise Exception.new("Either your Username or Password is incorrect.")
      end
      raise Exception.new("Please use your full email to log in.")
    end
  end
end