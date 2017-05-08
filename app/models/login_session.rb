class LoginSession
  attr_reader :success, :user, :xmlrpc_token, :timestamp

  def initialize(user, xmlrpc, success = true)
    @success = success
    @user = user
    @xmlrpc_token = xmlrpc.token
    @timestamp = Time.now
  end

  def success?
    @success
  end

  def self.session_version
    # increment if something changes that requires expiring all the sessions
    1
  end

  def self.yet_active?(session, email)
    session_timestamp = session[:session_timestamp]
    session_timestamp = Time.parse(session_timestamp) if String === session_timestamp
    case
      when session[:email].nil?
        false
      when email != session[:email]
        false
      when session_version != session[:session_version]
        false
      when (Time.now - session_timestamp) > 24.hours
        false
      else
        true
    end
  end

  def to_h
    { user_id: user_id, token: xmlrpc_token, success: success }
  end

  def kerberos_login
    user.kerberos_login
  end

  def user_token
    user.authentication_token
  end

  def user_email
    user.email
  end

  def user_id
    user.id
  end

  def user_display_name
    user.display_name
  end

  def set_session(session)
    if success? && user_id && xmlrpc_token
      session[:user] = user_id
      session[:email] = user_email
      session[:token] = xmlrpc_token
      session[:session_version] = self.class.session_version
      session[:session_timestamp] = timestamp
    end
  end
end
