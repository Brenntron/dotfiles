require 'snort_doc_publisher'

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
        file_contents = permitted_params['rule_update'].tempfile.read
        JSON.pretty_generate(SnortDocPublisher.gen_snort_doc_yaml(file_contents))
      end
    end

  end
end
