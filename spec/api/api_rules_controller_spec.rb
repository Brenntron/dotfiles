describe API::V1::Rules do
  describe "GET gids/:gid/sids/:sid", type: :api do
    it "gets a rule" do
      current_user = FactoryGirl.create(:user)
      puts "*** current_user = #{current_user.inspect}"
      get "/api/v1/rules/gids/1/sids/19500", headers: {'Token' => current_user.authentication_token}
      puts ">>> response.body = #{response.body.inspect}"
      expect(response).to be_success
    end
  end
end
