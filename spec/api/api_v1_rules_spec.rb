describe API::V1::Rules do
  before(:context) do
    @current_user = FactoryBot.create(:current_user)
    @current_user.roles << FactoryBot.create(:analyst_role)
    @std_headers = {'Token' => @current_user.authentication_token}
    @std_params = { headers: @std_headers }
  end

  describe "PUT gids/:gid/sids/:sid", type: :api do
    before (:context) do
      analyst_role = Role.where(role: 'analyst').first || FactoryBot.create(:analyst_role)
      @current_user.roles << analyst_role unless @current_user.has_role?('analyst')
    end

    # TODO implement API Key
     it "edits a rule" #do
    #   @rule = FactoryBot.create(:synched_rule)
    #   @rule_content = %Q~alert tcp $EXTERNAL_NET $FILE_DATA_PORTS -> $HOME_NET any (msg:"BROWSER-PLUGINS mess"; flow:to_client,established; file_data; content:"Msxml2.FreeThreadedDOMDocument.6.0"; fast_pattern:only; content:".definition("; nocase; metadata:policy balanced-ips drop, policy security-ips drop, service ftp-data, service http, service imap, service pop3; classtype:attempted-user; sid:#{@rule.sid}; rev:#{@rule.rev};)~
    #
    #   put "/api/v1/rules/gids/#{@rule[:gid]}/sids/#{@rule[:sid]}",
    #       { params: { rule: { rule_content: @rule_content } },
    #         headers: @std_headers }
    #
    #   # expect(response.code).to eq(200)
    #   expect(response).to be_success
    #
    #   rule = Rule.find(@rule.id)
    #   expect(rule.rule_content).to eq(@rule_content)
    # end
  end

  describe "PUT gids/:gid/sids/:sid/revert", type: :api do
    before (:context) do
      analyst_role = Role.where(role: 'analyst').first || FactoryBot.create(:analyst_role)
      @current_user.roles << analyst_role unless @current_user.has_role?('analyst')
    end

    # TODO implement API Key
    it "edits a rule" #do
    #   @rule = FactoryBot.create(:edited_rule)
    #
    #   put "/api/v1/rules/gids/#{@rule[:gid]}/sids/#{@rule[:sid]}/revert", @std_params
    #
    #   expect(response).to be_success
    #
    #   rule = Rule.find(@rule.id)
    #   expect(rule.rule_content).to_not eq(@rule.rule_content)
    # end

  end
end
