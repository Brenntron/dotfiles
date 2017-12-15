class API::V2::RuleUpdates < Grape::API
  include API::V2::Defaults
  # include API::WebAuthentication
  # include API::BugzillaLogin

  resource :rule_updates do

    params do
      optional :rule_update, type: File, desc: "API to post a rule update file from the group publishing snort rules."
    end
    post "", root: :rule_updates do
      std_api_v2 do
        # byebug
        file_content = permitted_params['rule_update'].tempfile.read
        "Hi curl!"
      end
    end
  end
end
