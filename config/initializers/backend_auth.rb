# Here we set backend_auth.
#
# Normally, as in production, the apache web server authenticates the user from kerberos
# and passes the values to our Rails app via HTTP headers.
# In development and test, we don't use apache, and may need to set values
# using UNIX environment variables.

Rails.configuration.backend_auth = {}
if Rails.env.development? || Rails.env.test?
  Rails.configuration.backend_auth = {
      default_remote_user: ENV['remote_user'],
      authenticate_email: ENV['authenticate_email'],
      authenticate_cvs_username: ENV['authenticate_cvs_username'],
      authenticate_cec_username: ENV['authenticate_cec_username'],
      authenticate_display_name: ENV['authenticate_display_name']
  }
end
