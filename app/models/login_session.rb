class LoginSession
  attr_reader :success, :user, :xmlrpc_token

  def initialize(user, xmlrpc, success = true)
    @success = success
    @user = user
    @xmlrpc_token = xmlrpc.token
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
end
