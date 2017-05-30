describe API::V1::Rules do
  describe "GET gids/:gid/sids/:sid", type: :api do
    before(:context) do
      @current_user = FactoryGirl.create(:current_user)
      @std_headers = { headers: {'Token' => @current_user.authentication_token} }
    end

    it "gets a rule from database" do
      rule = FactoryGirl.create(:synched_rule)

      get "/api/v1/rules/gids/#{rule.gid}/sids/#{rule.sid}", @std_headers

      expect(response).to be_success

      data = JSON.parse(response.body)
      rule_attrs = data["rule"]
      expect(rule_attrs["sid"]).to eq(rule.sid)
      expect(rule_attrs["gid"]).to eq(rule.gid)
    end

    it "gets a rule from repo" do
      rule = FactoryGirl.attributes_for(:synched_rule, gid: 1, sid: 19500)

      get "/api/v1/rules/gids/#{rule[:gid]}/sids/#{rule[:sid]}", @std_headers

      expect(response).to be_success

      data = JSON.parse(response.body)
      rule_attrs = data["rule"]
      expect(rule_attrs["sid"]).to eq(rule[:sid])
      expect(rule_attrs["gid"]).to eq(rule[:gid])
    end
  end
end
