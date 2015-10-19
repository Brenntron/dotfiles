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
           unclassified: 0,
           confidential: 1,
           secret: 2,
           top_secret: 3,
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

  def self.login_user(params, request)
    begin
       #we need to get the bugzilla user email by looking up the keerberos login Email using request.env['REMOTE_USER']
      xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
      xmlrpc.bugzilla_login(Bugzilla::User.new(xmlrpc), Rails.configuration.ember_app[:bugzilla_login], Rails.configuration.ember_app[:bugzilla_key])
      kerberos_login = params[:kerberos_login] || request.env['REMOTE_USER'] || Rails.configuration.ember_app[:remote_user]

      raise Exception.new("You are not logged into Kerberos. Please try again.") if kerberos_login.nil?
      user = User.where("kerberos_login=?", kerberos_login).first_or_create do |new_record|
        new_record.email = ""
        new_record.kerberos_login = kerberos_login
        new_record.cvs_username = ""
        new_record.committer = 'true'
        new_record.class_level = 'unclassified'
      end

      user.confirmed = 'true'
      user.updated_at = Time.now

      if user.email == "" #this person has had an account created programatically but they havn't signed in yet.
        # we need to look up the user in LDAP and get their email
      end

      user.ensure_authentication_token #make sure the user has a token generated
      resource = {
          :success => true,
          :xmlrpc_token => xmlrpc.token,
          :kerberos_login => user.kerberos_login,
          :user_token => user.authentication_token, #this must be called user_token for the ember app session to persist
          :user_email => user.email, #this also ust be called user_email for the ember app session to persist
          :user_id => user.id
      }

      raise Exception.new("Error signing in. Please contact the administrator.") unless user.save
      return resource

    end
  end
end