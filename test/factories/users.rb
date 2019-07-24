FactoryBot.define do
  factory :user do
    password                            { "password" }
    password_confirmation               { "password" }
    current_sign_in_ip                  { "127.0.0.1" }
    authentication_token                { "12345" }
    parent_id                           {nil}
    class_level                         { 3 }
    sequence :cvs_username do |nn|
      "user#{nn}"
    end
    email { "#{cvs_username}@cisco.com" }

    factory :vrt_incoming_user do
      display_name                      { "Vrt Incoming" }
      cvs_username                      { "vrtincom" }
      cec_username                      { "vrtincom" }
      kerberos_login                    { "vrtincom" }
      email                             { "vrt-incoming@sourcefire.com" }
    end

    factory :current_user do
      display_name                      { ENV['authenticate_display_name'] }
      cec_username                      { ENV['authenticate_cec_username'] }
      cvs_username                      { ENV['authenticate_cvs_username'] }
      kerberos_login                    { ENV['remote_user'] }
      email                             { ENV['authenticate_email'] }
      authentication_token              { SecureRandom.hex(10) }
    end

    factory :fake_user do
      transient do
        sequence :first_name do |nn|
          %w[James Ronald George William Barack Hillary][nn - 1] || Faker::Name.first_name
        end
        sequence :last_name do |nn|
          %w[Washington Adams Jefferson Madison Monroe Adams][nn - 1] || Faker::Name.last_name
        end
      end
      display_name { "#{first_name} #{last_name}" }
      cec_username { "#{first_name[0..3]}#{last_name[0..3]}".downcase }
      cvs_username { cec_username }
      kerberos_login { cec_username }
    end
  end
end
