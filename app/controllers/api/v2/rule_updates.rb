require 'snort_doc_publisher'

class API::V2::RuleUpdates < Grape::API
  include API::V2::Defaults
  # include API::BugzillaLogin

  default_format :json
  format :json

  resource :rule_updates do

    params do
      optional :rule_update, type: File, desc: "API to post a rule update file from the group publishing snort rules."
    end
    content_type :txt, 'application/json'
    format :txt
    post "", root: :rule_updates do
      std_api_v2 do
        file_contents = permitted_params['rule_update'].tempfile.read
        # SnortDocPublisher.gen_snort_doc_yaml(file_contents)
        JSON.pretty_generate(SnortDocPublisher.gen_snort_doc_from_yaml(file_contents))
      end
    end

  end
end
