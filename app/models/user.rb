class User < ActiveRecord::Base
  has_many :bugs
  has_many :team_member_relationships, :class_name => "Relationship"
  has_many :team_members, :through => :team_member_relationships
  has_many :manager_relationships, :class_name => "Relationship", :foreign_key => "team_member_id"
  has_many :managers, :through => :manager_relationships, :source => :user

  before_save :ensure_authentication_token
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  enum class_level: {
      unclassified:   0,
      confidential:   1,
      secret:         2,
      top_secret:     3,
      top_secret_sci: 4
  }

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

  def self.login_user(params,request)
    begin
      xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
      xmlrpc.bugzilla_login(Bugzilla::User.new(xmlrpc), params[:user][:email].gsub("@#{Rails.configuration.bugzilla_domain}",""), params[:user][:password])

      user = User.where("email=?", params[:user][:email]).first_or_create do |new_record|
        new_record.email          = params[:user][:email]
        new_record.cvs_username   = params[:user][:email].gsub("@#{Rails.configuration.bugzilla_domain}","")
        new_record.password       = params[:user][:password]
        new_record.committer      = 'true'
        new_record.class_level    = 'unclassified'
      end

      user.confirmed      = 'true'
      user.updated_at     = Time.now
      user.bugzilla_token = xmlrpc.token

      if user.valid_password?(params[:user][:password]) #devise takes care of password checking but this wont work if the user has an account but no password.
        user.ensure_authentication_token #make sure the user has a token generated
        resource = {
            :success => true,
            :xmlrpc_token => xmlrpc.token,
            :user_token => user.authentication_token, #this must be called user_token for the ember app session to persist
            :user_email => user.email, #this also ust be called user_email for the ember app session to persist
            :user_id => user.id
        }
        raise Exception.new("Error signing in. Please use full email as your login.") unless user.save
        return resource
      elsif user.kerberos_login == "generated" #this person has had an account created programatically but they havn't signed in yet.
        user.class_level    = 'unclassified'
        user.kerberos_login = request.env['REMOTE_USER']
        user.ensure_authentication_token #make sure the user has a token generated
        user.password       = params[:user][:password]
        resource = {
            :success => true,
            :xmlrpc_token => xmlrpc.token,
            :user_token => user.authentication_token, #this must be called user_token for the ember app session to persist
            :user_email => user.email, #this also ust be called user_email for the ember app session to persist
            :user_id => user.id
        }
        raise Exception.new("Error signing in. Please use full email as your login.") unless user.save
        return resource
      else
        raise Exception.new("Either your Username or Password is incorrect.")
      end
      raise Exception.new("Please use your full email to log in.")
    end
  end
end