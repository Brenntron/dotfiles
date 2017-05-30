describe API::V1::Rules do
  describe "GET gids/:gid/sids/:sid", type: :api do
    it "gets a rule" do
      get "/api/v1/rules/gids/1/sids/19500"
    end
  end
end
