module AuthenticationHelper
  def create_login_session(user = FactoryBot.create(:current_user), roles: [])
    user.roles += roles.map do |role_name|
      first_role = Role.where(role: role_name).first
      first_role || Role.create(role: role_name, org_subset: OrgSubset.find_or_create_by(name: 'everyone'))
    end
    post user_session_path,
         headers: {'REMOTE_USER' => user.cvs_username,
                   'AUTHORIZE_MAIL' => user.email,
         },
         params: {'uname' => Rails.configuration.bugzilla_username,
                  'psw' => Rails.configuration.bugzilla_password}
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :request
end
