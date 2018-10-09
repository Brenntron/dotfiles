module AuthenticationHelper
  def sign_in
    @user ||= FactoryBot.create(:user)
    @user.login_from_test
  end

  def login_sesssion(session)
    login = sign_in
    login.set_session(session)
  end

  def login(user = nil)
    # User.from_request(params, request)
    allow(User).to receive(:from_request).and_return(user || FactoryBot.create(:user))
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :request
end
