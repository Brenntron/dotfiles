FactoryGirl.define do
  factory :user do
    email "test@cisco.com"
    password "password"
    password_confirmation "password"
    current_sign_in_ip "127.0.0.1"
    authentication_token "12345"
  end
end