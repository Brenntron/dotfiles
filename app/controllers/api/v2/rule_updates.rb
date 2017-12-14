class API::V2::RuleUpdates < Grape::API
  include API::V2::Defaults

  resource :rule_updates do

    params do
      optional :rule_update, type: File, desc: "TBD"
    end
    post "", root: :rule_updates do
      std_api_v2 do
        byebug
        content = permitted_params['rule_update'].tempfile.read
        "Hi curl!"
      end
    end
  end
end
