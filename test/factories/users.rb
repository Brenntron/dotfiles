FactoryGirl.define do
  factory :user do
    email ENV['authenticate_email']
    password "password"
    password_confirmation "password"
    current_sign_in_ip "127.0.0.1"
    authentication_token "12345"
    display_name ENV['authenticate_display_name']
    cvs_username ENV['authenticate_cvs_username']
    kerberos_login ENV['remote_user']
    cec_username ENV['authenticate_cec_username']
    parent_id nil
  end
end
