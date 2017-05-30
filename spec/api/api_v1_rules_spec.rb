describe API::V1::Rules do
  describe "GET gids/:gid/sids/:sid", type: :api do
    before(:context) do
      @current_user = FactoryGirl.create(:current_user)
      @std_headers = { headers: {'Token' => @current_user.authentication_token} }
    end

    it "gets a rule" do
      get "/api/v1/rules/gids/1/sids/19500", @std_headers
      puts ">>> response.body = #{response.body.inspect}"
      expect(response).to be_success
    end
  end
end
