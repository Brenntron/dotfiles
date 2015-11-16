Rails.configuration.backend_auth = {
    :authenticate_email=>ENV['authenticate_email'],
    :authenticate_cvs_username=>ENV['authenticate_cvs_username'],
    :authenticate_cec_username=>ENV['authenticate_cec_username'],
    :authenticate_display_name=>ENV['authenticate_display_name']
}