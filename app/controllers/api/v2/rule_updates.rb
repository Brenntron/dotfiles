require 'snort_doc_publisher'

class API::V2::RuleUpdates < Grape::API
  include API::V2::Defaults
  # include API::BugzillaLogin

  default_format :json
  format :json

  resource :rule_updates do

    desc 'Get the snort rule doc JSON which results from the rule update YAML'
    params do
      requires :rule_update, type: File, desc: 'API to post a rule update file from the group publishing snort rules.'
      optional :do_download, type: Boolean, default: 'true', desc: 'True to download updates from NIST NVD'
      optional :do_publish, type: Boolean, default: 'true', desc: 'True to mark rules as has been published'
    end
    get "", root: :rule_updates do
      std_api_v2 do
        file_contents = permitted_params['rule_update'].tempfile.read
        SnortDocPublisher.publish_snort_doc_from_yaml(file_contents,
                                                      do_download: permitted_params['do_download'],
                                                      do_publish: permitted_params['do_publish'])
      end
    end

    desc 'Get the snort rule doc JSON which results from the rule update YAML'
    params do
      requires :rule_update, type: File, desc: 'API to post a rule update file from the group publishing snort rules.'
      optional :do_download, type: Boolean, default: 'true', desc: 'True to download updates from NIST NVD'
      optional :do_publish, type: Boolean, default: 'true', desc: 'True to mark rules as has been published'
    end
    content_type :txt, 'application/json'
    format :txt
    get "pretty", root: :rule_updates do
      std_api_v2 do
        file_contents = permitted_params['rule_update'].tempfile.read
        output_struct = SnortDocPublisher.publish_snort_doc_from_yaml(file_contents,
                                                                      do_download: permitted_params['do_download'],
                                                                      do_publish: permitted_params['do_publish'])
        JSON.pretty_generate(output_struct)
      end
    end

    params do
      requires :rule_update, type: File, desc: 'API to post a rule update file from the group publishing snort rules.'
      optional :do_download, type: Boolean, default: 'true', desc: 'True to download updates from NIST NVD'
      optional :do_publish, type: Boolean, default: 'true', desc: 'True to mark rules as has been published'
    end
    post "", root: :rule_updates do
      std_api_v2 do
        file_contents = permitted_params['rule_update'].tempfile.read
        Thread.new do
          permitted_params['rule_update'].tempfile.close
          output_struct = SnortDocPublisher.publish_snort_doc_from_yaml(file_contents,
                                                                        do_download: permitted_params['do_download'],
                                                                        do_publish: permitted_params['do_publish'])
          File.open('output.json', 'w') do |file|
            file.write(output_struct.to_json)
          end
        end
        'publish scheduled.'
      end
    end

  end
end
